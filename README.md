# su-exec-rs

switch user and group id, setgroups and exec.

## Description

su-exec-rs is a simple tool written in rust that will simply execute a program with different privileges. The program will be executed directly and it will not run as a child process (e.g. su and sudo). This avoids TTY and signal issues.

**Note: su-exec-rs depends on being run by the root user as non-root users do not have the permissions to change uid/gid.**

## Usage

Usage:

```shell
su-exec-rs user-spec command [args]
```

user-spec is either a user name (e.g. nobody) or user name and group name separated with colon (e.g. nobody:ftp). Numeric uid/gid values can be used instead of names.

As the root user:

```shell
su-exec-rs ubuntu:1000 /usr/sbin/caddy -conf /etc/Caddyfile
```

Example usage:

```shellsession
$ time docker run --rm -it ubuntu:latest su ubuntu -c 'ps aux'
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1 23.5  0.0   4332  2816 pts/0    Ss+  22:03   0:00 su ubuntu -c ps aux
ubuntu         7  0.0  0.0   8280  4224 ?        Rs   22:03   0:00 ps aux

real 0m0.554s
user 0m0.019s
sys 0m0.025s
```

```shellsession
$ time docker run --rm -it -v $PWD/su-exec-rs:/sbin/su-exec-rs:ro ubuntu:latest su-exec-rs ubuntu ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
ubuntu         1 23.5  0.0   7888  3712 pts/0    Rs+  22:05   0:00 ps aux

real 0m0.537s
user 0m0.017s
sys 0m0.026s
```

## Building

```shell
just build
```

## Why reinvent su-exec and gosu?

This does more or less exactly the same thing as [su-exec](https://github.com/ncopa/su-exec) and [gosu](https://github.com/tianon/gosu) but it is written in Rust.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
