use libc::{self, c_char, gid_t, uid_t};
use std::ffi::CString;
use std::os::unix::ffi::OsStrExt;
use std::{env, io, mem, process, ptr};

fn usage(program: &str) -> ! {
    eprintln!("Usage: {} user-spec command [args]", program);
    process::exit(1);
}

fn error(msg: &str) -> ! {
    eprintln!("Error: {} - {}", msg, io::Error::last_os_error());
    process::exit(1);
}

fn parse_user_spec(user_spec: &str) -> (&str, Option<&str>) {
    user_spec
        .split_once(':')
        .map_or((user_spec, None), |(u, g)| (u, Some(g)))
}

fn get_uid(user: &str) -> uid_t {
    if user.is_empty() {
        unsafe { libc::getuid() }
    } else {
        user.parse::<uid_t>().unwrap_or_else(|_| unsafe {
            let c_user = CString::new(user).unwrap();
            let pw = libc::getpwnam(c_user.as_ptr());
            if pw.is_null() {
                error("getpwnam");
            }
            (*pw).pw_uid
        })
    }
}

fn get_gid(group: Option<&str>, current_gid: gid_t) -> gid_t {
    match group {
        Some(g) if !g.is_empty() => g.parse::<gid_t>().unwrap_or_else(|_| unsafe {
            let c_group = CString::new(g).unwrap();
            let gr = libc::getgrnam(c_group.as_ptr());
            if gr.is_null() {
                error("getgrnam");
            }
            (*gr).gr_gid
        }),
        _ => current_gid,
    }
}

unsafe fn set_groups(pw: *const libc::passwd, gid: gid_t) {
    if pw.is_null() {
        if libc::setgroups(1, &gid) < 0 {
            error("setgroups");
        }
    } else {
        let mut ngroups: i32 = 0;
        let mut glist: *mut gid_t = ptr::null_mut();

        loop {
            let r = libc::getgrouplist((*pw).pw_name, gid, glist, &mut ngroups);
            if r >= 0 {
                if libc::setgroups(ngroups as usize, glist) < 0 {
                    error("setgroups");
                }
                break;
            }
            glist = libc::realloc(
                glist as *mut libc::c_void,
                (ngroups as usize * mem::size_of::<gid_t>()) as libc::size_t,
            ) as *mut gid_t;
            if glist.is_null() {
                error("malloc");
            }
        }
        if !glist.is_null() {
            libc::free(glist as *mut libc::c_void);
        }
    }
}

fn main() {
    let args: Vec<CString> = env::args_os()
        .map(|arg| {
            CString::new(arg.as_bytes()).unwrap_or_else(|_| {
                eprintln!("Invalid argument containing null byte");
                process::exit(1);
            })
        })
        .collect();

    if args.len() < 3 {
        usage(&args[0].to_string_lossy());
    }

    let user_spec = args[1].to_str().unwrap();
    let (user, group) = parse_user_spec(user_spec);

    let uid = get_uid(user);
    let mut gid = unsafe { libc::getgid() };

    unsafe {
        let pw = libc::getpwuid(uid);

        if !pw.is_null() {
            gid = (*pw).pw_gid;
        }

        libc::setenv(
            b"HOME\0".as_ptr() as *const c_char,
            if !pw.is_null() {
                (*pw).pw_dir
            } else {
                b"/\0".as_ptr() as *const c_char
            },
            1,
        );

        gid = get_gid(group, gid);

        set_groups(pw, gid);

        if libc::setgid(gid) < 0 {
            error("setgid");
        }

        if libc::setuid(uid) < 0 {
            error("setuid");
        }

        // Prepare arguments for execvp
        let mut cmd_args: Vec<*const c_char> = args[2..].iter().map(|s| s.as_ptr()).collect();
        cmd_args.push(ptr::null());

        libc::execvp(cmd_args[0], cmd_args.as_ptr());
        error("execvp");
    }
}
