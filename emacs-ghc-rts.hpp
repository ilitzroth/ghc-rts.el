#ifndef EMACS_HIEDB_H_
#define EMACS_HIEDB_H_
#include <emacs-module.h>



extern "C"
{
  using user_finalizer_t = void (*) (void *) EMACS_NOEXCEPT;
  using emacs_function_t = emacs_value(*)(
    emacs_env *env_,
    ptrdiff_t nargs,
    emacs_value *args,
    void *data) noexcept;
}



#endif // EMACS_HIEDB_H_
