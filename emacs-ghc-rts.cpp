#include <malloc.h>
#include <string.h>
#include <Rts.h>
#include "emacs-ghc-rts.hpp"
#include <assert.h>
#include <alloca.h>
// #include <iostream>
int plugin_is_GPL_compatible;

namespace {
emacs_env*
check_emacs_version(struct emacs_runtime* ert) EMACS_NOEXCEPT
{
  if ((unsigned)ert->size < sizeof (*ert))
    return nullptr;

  emacs_env *env = ert->get_environment (ert);
  if ((unsigned)env->size < sizeof (*env))
    return nullptr;
  return env;
}

enum class RTSStatus {
  NotInitialized,
  Initialized,
  Exited
};
RTSStatus rts_status;

emacs_value
status_to_symbol(emacs_env* env)
{
  switch (rts_status)
  {
    case RTSStatus::NotInitialized:
      return env->intern(env, ":not-initialized");
    case RTSStatus::Initialized:
      return env->intern(env, ":initialized");
    case RTSStatus::Exited:
      return env->intern(env, ":exited");
  }
  __builtin_unreachable();
}

emacs_value
c_to_emacs_bool(
  emacs_env* env,
  bool c)
{
  return env->intern(
    env,
    c ? "t" : "nil");
}

emacs_value
emacs_init_rts(
  emacs_env* env,
  ptrdiff_t nargs,
  emacs_value args[],
  void*) noexcept
{
  switch (rts_status)
  {
    case RTSStatus::Exited:
    case RTSStatus::Initialized:
      return status_to_symbol(env);

    case RTSStatus::NotInitialized:
      //      std::cout << "nargs: " << nargs << std::endl;
      int argc = nargs;
      char **argv = (char**) alloca(sizeof(char*) * (argc + 1));
      argv[argc] = nullptr;

      RtsConfig conf = defaultRtsConfig;
      conf.rts_opts_enabled = RtsOptsAll;
      for(int i = 0; i < argc; ++i)
      {
        ptrdiff_t size = 0;
        env->copy_string_contents(
          env,
          args[i],
          nullptr,
          &size);
        char* rts_arg = (char*)alloca(sizeof(char)*size);
        env->copy_string_contents(
          env,
          args[i],
          rts_arg,
          &size);
        argv[i] = rts_arg;
        // std::cout << "Passing arg: " << argv[i] << std::endl;
      }
      char **pargv = argv;

      hs_init_ghc(&argc, &pargv, conf);
      rts_status = RTSStatus::Initialized;
      return status_to_symbol(env);
  }
  __builtin_unreachable();
}

emacs_value
emacs_get_rts_status(
  emacs_env* env,
  ptrdiff_t nargs,
  emacs_value args[],
  void*) noexcept
{
  return status_to_symbol(env);
}

emacs_value
emacs_exit_rts(
  emacs_env* env,
  ptrdiff_t nargs,
  emacs_value args[],
  void*) noexcept
{
  if(rts_status == RTSStatus::Initialized)
  {
    hs_exit();

    rts_status = RTSStatus::Exited;
  }
  return
    status_to_symbol(env);
}

emacs_value
emacs_rts_is_profiled(
  emacs_env* env,
  ptrdiff_t nargs,
  emacs_value args[],
  void*) noexcept
{
  return c_to_emacs_bool(
    env,
    rts_isProfiled());
}

emacs_value
emacs_rts_is_dynamic(
  emacs_env* env,
  ptrdiff_t nargs,
  emacs_value args[],
  void*) noexcept
{
  return c_to_emacs_bool(
    env,
    rts_isDynamic());
}

emacs_value
emacs_get_allocations(
  emacs_env* env,
  ptrdiff_t nargs,
  emacs_value args[],
  void*) noexcept
{
  return env->make_integer(
    env,
    getAllocations());
}

emacs_value
emacs_rts_stats_enabled(
  emacs_env* env,
  ptrdiff_t nargs,
  emacs_value args[],
  void*) noexcept
{
  return c_to_emacs_bool(
    env,
    getRTSStatsEnabled());
}
// void getRTSStats (RTSStats *s);

class EmacsFunctionMaker
{
public:
  EmacsFunctionMaker(emacs_env* env);

  void
  operator()(
    int min_args,
    int max_args,
    emacs_function_t fn,
    const char* function_doc,
    const char* function_name,
    void* data = nullptr);
private:
  emacs_env* env_;
};

EmacsFunctionMaker::EmacsFunctionMaker(emacs_env* env)
  : env_(env)
{}

void
EmacsFunctionMaker::operator()(
  int min_args,
  int max_args,
  emacs_function_t fn,
  const char* function_name,
  const char* function_doc,
  void* data)
{
  emacs_value func = env_->make_function(
    env_,
    min_args,
    max_args,
    fn,
    function_doc,
    data);
  emacs_value symbol = env_->intern(env_, function_name);
  emacs_value args[] = { symbol, func };
  env_->funcall(
    env_,
    env_->intern(env_,
                 "defalias"),
    2,
    args);
}

}
emacs_module_init(struct emacs_runtime* ert) EMACS_NOEXCEPT
{
  emacs_env* env = check_emacs_version(
    ert);
  if (not env)
  {
    return -1;
  }
  rts_status = RTSStatus::NotInitialized;

  EmacsFunctionMaker fmaker(env);

  fmaker(
    0,
    emacs_variadic_function,
    emacs_init_rts,
    "ghc-rts::init-rts",
    R"(Initialize the ghc runtime system.
Returns one of ':initialize or ':exited)");

  fmaker(
    0,
    0,
    emacs_get_rts_status,
    "ghc-rts::get-rts-status",
    R"(Get the status of the ghc runtime system.
Returns one of ':not-initialized ':initialized ':exited.)");

  fmaker(
    0,
    0,
    emacs_exit_rts,
    "ghc-rts::exit-rts",
    R"(Exit the ghc runtime system.
Returns ':exited)");

  fmaker(
    0,
    0,
    emacs_rts_is_profiled,
    "ghc-rts::profiledp",
    R"(Return whether the rts is profiled)");


  fmaker(
    0,
    0,
    emacs_rts_is_dynamic,
    "ghc-rts::dynamicp",
    R"(Return whether the rts is dynamically loaded)");

  fmaker(
    0,
    0,
    emacs_get_allocations,
    "ghc-rts::num-allocations",
    R"(Return the number of allocations performed.)");

  fmaker(
    0,
    0,
    emacs_rts_stats_enabled,
    "ghc-rts::stats-enabled-p",
    R"(Return wheter RTS statistics are enabled)");
  return 0;
}
