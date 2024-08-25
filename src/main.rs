use libc::{self, gid_t, uid_t};
use std::env;
use std::os::unix::process::CommandExt;
use std::process::Command;
use users::os::unix::UserExt;
use users::{get_group_by_name, get_user_by_name, get_user_by_uid, User};

struct UserInfo {
    uid: uid_t,
    gid: gid_t,
    user: Option<User>,
}

fn usage(program: &str) -> ! {
    eprintln!("Usage: {} user-spec command [args]", program);
    std::process::exit(1);
}

fn parse_user_spec(user_spec: &str) -> (&str, Option<&str>) {
    user_spec
        .split_once(':')
        .map_or((user_spec, None), |(u, g)| (u, Some(g)))
}

fn get_target_uid(user: &str) -> Result<uid_t, Box<dyn std::error::Error>> {
    if user.is_empty() {
        Ok(unsafe { libc::getuid() })
    } else {
        user.parse::<u32>()
            .map(|u| u as uid_t)
            .or_else(|_| {
                get_user_by_name(user)
                    .map(|u| u.uid())
                    .ok_or("User not found")
            })
            .map_err(|e| format!("Failed to get uid for user: {}. Error: {}", user, e).into())
    }
}

fn get_user_info(target_uid: uid_t) -> UserInfo {
    let gid = unsafe { libc::getgid() };
    let user = get_user_by_uid(target_uid);
    let gid = user.as_ref().map_or(gid, |u| u.primary_group_id());
    UserInfo {
        uid: target_uid,
        gid,
        user,
    }
}

fn set_home_env(user: &Option<User>) {
    let home = user
        .as_ref()
        .and_then(|u| u.home_dir().to_str())
        .unwrap_or("/");
    env::set_var("HOME", home);
}

fn get_target_gid(
    group: Option<&str>,
    current_gid: gid_t,
) -> Result<gid_t, Box<dyn std::error::Error>> {
    match group {
        Some(g) if !g.is_empty() => g
            .parse::<u32>()
            .map(|g| g as gid_t)
            .or_else(|_| {
                get_group_by_name(g)
                    .map(|g| g.gid())
                    .ok_or("Group not found")
            })
            .map_err(|e| format!("Failed to get gid for group: {}. Error: {}", g, e).into()),
        _ => Ok(current_gid),
    }
}

unsafe fn set_groups(gid: gid_t) -> Result<(), Box<dyn std::error::Error>> {
    if libc::setgroups(1, &gid) != 0 {
        return Err(std::io::Error::last_os_error().into());
    }
    Ok(())
}

fn set_user_groups(user: &User, gid: gid_t) -> Result<(), Box<dyn std::error::Error>> {
    let groups: Vec<gid_t> = user
        .groups()
        .unwrap_or_default()
        .iter()
        .map(|g| g.gid())
        .collect();

    unsafe {
        if !groups.is_empty() {
            if libc::setgroups(groups.len() as libc::size_t, groups.as_ptr()) != 0 {
                return Err(std::io::Error::last_os_error().into());
            }
        } else {
            set_groups(gid)?;
        }
    }
    Ok(())
}

unsafe fn set_ids(gid: gid_t, uid: uid_t) -> Result<(), Box<dyn std::error::Error>> {
    if libc::setgid(gid) != 0 || libc::setuid(uid) != 0 {
        return Err(std::io::Error::last_os_error().into());
    }
    Ok(())
}

fn exec_command(args: &[String]) -> std::io::Error {
    Command::new(&args[0]).args(&args[1..]).exec()
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().skip(1).collect();
    if args.len() < 2 {
        usage(&env::args().next().unwrap());
    }

    let (user, group) = parse_user_spec(&args[0]);
    let target_uid = get_target_uid(user)?;
    let mut user_info = get_user_info(target_uid);

    set_home_env(&user_info.user);

    user_info.gid = get_target_gid(group, user_info.gid)?;

    unsafe {
        match &user_info.user {
            Some(user) => set_user_groups(user, user_info.gid)?,
            None => set_groups(user_info.gid)?,
        }

        set_ids(user_info.gid, user_info.uid)?;
    }

    let err = exec_command(&args[1..]);
    Err(Box::new(err))
}
