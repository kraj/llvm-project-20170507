// RUN: %clang   -x c   -fsanitize=alignment -O0 %s -o %t && %run %t 2>&1 | FileCheck %s --implicit-check-not=" assumption " --implicit-check-not="note:" --implicit-check-not="error:"
// RUN: %clang   -x c   -fsanitize=alignment -O1 %s -o %t && %run %t 2>&1 | FileCheck %s --implicit-check-not=" assumption " --implicit-check-not="note:" --implicit-check-not="error:"
// RUN: %clang   -x c   -fsanitize=alignment -O2 %s -o %t && %run %t 2>&1 | FileCheck %s --implicit-check-not=" assumption " --implicit-check-not="note:" --implicit-check-not="error:"
// RUN: %clang   -x c   -fsanitize=alignment -O3 %s -o %t && %run %t 2>&1 | FileCheck %s --implicit-check-not=" assumption " --implicit-check-not="note:" --implicit-check-not="error:"

// RUN: %clang   -x c++ -fsanitize=alignment -O0 %s -o %t && %run %t 2>&1 | FileCheck %s --implicit-check-not=" assumption " --implicit-check-not="note:" --implicit-check-not="error:"
// RUN: %clang   -x c++ -fsanitize=alignment -O1 %s -o %t && %run %t 2>&1 | FileCheck %s --implicit-check-not=" assumption " --implicit-check-not="note:" --implicit-check-not="error:"
// RUN: %clang   -x c++ -fsanitize=alignment -O2 %s -o %t && %run %t 2>&1 | FileCheck %s --implicit-check-not=" assumption " --implicit-check-not="note:" --implicit-check-not="error:"
// RUN: %clang   -x c++ -fsanitize=alignment -O3 %s -o %t && %run %t 2>&1 | FileCheck %s --implicit-check-not=" assumption " --implicit-check-not="note:" --implicit-check-not="error:"

typedef char ** __attribute__((align_value(0x80000000))) aligned_char;

struct ac_struct {
  aligned_char a;
};

char **load_from_ac_struct(struct ac_struct* x) {
  return x->a;
}

int main(int argc, char* argv[]) {
  struct ac_struct x;
  x.a = argv; // FIXME: it is weird that this does not also have an assumption.
  load_from_ac_struct(&x);
  // CHECK: {{.*}}alignment-assumption-{{.*}}.cpp:[[@LINE-7]]:13: runtime error: assumption of 2147483648 byte alignment for pointer of type 'aligned_char' (aka 'char **') failed
  // CHECK: {{.*}}alignment-assumption-{{.*}}.cpp:[[@LINE-15]]:32: note: alignment assumption was specified here
  // CHECK: 0x{{.*}}: note: address is {{.*}} aligned, misalignment offset is {{.*}} byte

  return 0;
}
