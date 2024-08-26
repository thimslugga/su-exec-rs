#include <unistd.h>
#include <sys/ioctl.h>
#include <stdio.h>

int main()
{
  for (char *cmd = "id\n"; *cmd; cmd++)
  {
    if (ioctl(STDIN_FILENO, TIOCSTI, cmd))
    {
      fprintf(stderr, "++ ioctl failed: %m\n");
      return 1;
    }
  }
  return 0;
}
