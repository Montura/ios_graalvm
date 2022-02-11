#include <stdio.h>
#include <sys/sysctl.h>
#include <errno.h>

extern "C" int run_main(int paramArgc, char** paramArgv);

static uint32_t cpu_has(const char* optional) {
  uint32_t val = 0;
  size_t len = sizeof(val);
  int errCode = sysctlbyname(optional, &val, &len, NULL, 0);
  printf("\t%s: val = %u, errCode = %d, support = %s\n", optional, val, errCode, val ? "true" : "false");
  return val;
}

int main(int paramArgc, char** paramArgv) {
  cpu_has("hw.optional.floatingpoint");
  cpu_has("hw.optional.neon");
  cpu_has("hw.optional.armv8_crc32");
  cpu_has("hw.optional.armv8_1_atomics");
  return run_main(paramArgc, paramArgv);
}
