#include <Foundation/Foundation.h>

#include <stdio.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <mach/machine.h>
#include <errno.h>

extern "C" int run_main(int paramArgc, char** paramArgv);

NSString *get_cpu_type() {
    NSMutableString *cpu = [[NSMutableString alloc] init];
    size_t size;
    cpu_type_t type;
    cpu_subtype_t subtype;
    size = sizeof(type);
    int errCode = sysctlbyname("hw.cputype", &type, &size, NULL, 0);
    if (errCode != 0) {
        printf("sysctlbyname error: %d", errCode);
    }

    size = sizeof(subtype);
    sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);
    if (errCode != 0) {
        printf("sysctlbyname error: %d", errCode);
    }

    if ((type == CPU_TYPE_ARM64) && (subtype == CPU_SUBTYPE_ARM64_V8)) {
        [cpu appendString:@"ARM64_V8"];
    }
    return cpu;
}

uint32_t cpu_has(const char* optional) {
  uint32_t val = 0;
  size_t len = sizeof(val);
  int errCode = sysctlbyname(optional, &val, &len, NULL, 0);
  printf("  %s: val = %u, errCode = %d, support = %s\n", optional, val, errCode, val ? "true" : "false");
  return val;
}

int main(int paramArgc, char** paramArgv) {
  NSString* cpu_type = get_cpu_type();
  const char* data = ([cpu_type length] != 0) ? [cpu_type UTF8String] : "is not ARM64_v8";
  printf("CPU: %s\n", data);
  cpu_has("hw.optional.floatingpoint");
  cpu_has("hw.optional.neon");
  cpu_has("hw.optional.armv8_crc32");
  cpu_has("hw.optional.armv8_1_atomics");
  return run_main(paramArgc, paramArgv);
}
