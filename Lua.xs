#include <lua.h>
#include <lualib.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct lua_Object {
  lua_State * L;
  SV        * nil;
  HV        * funcs;
  char      * error;
} lua_Object;
typedef lua_Object * Outline__Lua;

int strtoflags(char *);

void lua_push_perl_array {
  register int i;
  lua_newtable(L);

  for (i = 0; i <= av_len(av); i++) {
    SV **ptr = av_fetch(av, i, FALSE);
    lua_pushnumber(L, (lua_Number)i+1);
    if (ptr) 
      push_val(L, *ptr);
    else
      lua_pushnil(L);
    lua_settable(L, -3);
  }
}

void lua_push_perl_hash (lua_State *L, HV *hv) {
  register HE* he;
  
  lua_newtable(L);
  hv_iterinit(hv);

  while (he = hv_iternext(hv)) {
    I32 len;
    char *key;
    key = hv_iterkey(he, &len);
    lua_pushlstring(L, key, len);
    push_val(L, hv_iterval(hv, he));
    lua_settable(L, -3);
  }
}

void lua_push_perl_ref(lua_State *L, SV *val) {
  switch (SvTYPE(val)) {
	  case SVt_PVAV:
	    lua_push_perl_array(L, (AV*)val);
	    return;
	  case SVt_PVHV:
	    lua_push_perl_hash(L, (HV*)val);
	    return;
	  case SVt_PVCV:
	    lua_push_perl_funcref(L, (CV*)val);
	    return;
	  case SVt_PVGV:
	    lua_push_perl_io(L, IoIFP(sv_2io(val)));
	    return;
	  default:
	    croak("Attempt to pass unsupported reference type (%s) to Lua", sv_reftype(val, 0));
  }
}

void lua_push_perl_var(lua_State *L, SV *val) {
  switch (SvTYPE(val)) {
    case SVt_RV:
      lua_push_perl_ref(L, SvRV(val));
      return;
    case SVt_IV: 
      lua_pushnumber(L, (lua_Number)SvIV(val));
      return;
    case SVt_NV:
      lua_pushnumber(L, (lua_Number)SvNV(val));
      return;
    case SVt_PV: case SVt_PVIV: 
    case SVt_PVNV: case SVt_PVMG:
    {
      STRLEN n_a;
      char *cval = SvPV(val, n_a);
      lua_pushlstring(L, cval, n_a);
      return;
    }
  }
}

void lua_push_io (lua_State *L, PerlIO *pio) {
    FILE **fp = (FILE**)lua_newuserdata(L, sizeof(FILE*));
    *fp = PerlIO_exportFILE(pio, NULL);
    luaL_getmetatable(L, "FILE*");
    lua_setmetatable(L, -2);
}

SV* perl_from_lua_val(lua_Object *self, int i) {
  lua_State *L  = self->L;

  /* We need to use the object to find out things like nil and
   * booleans' actual values
   */
  switch (lua_type(L, i)) {
    case LUA_TNIL:
      return &PL_sv_undef;

    case LUA_TBOOLEAN:
      return lua_toboolean(L, i) ? &PL_sv_yes : &PL_sv_no;

    case LUA_TNUMBER:
      return newSVnv(lua_tonumber(L, i));

    case LUA_TSTRING:
      return newSVpvn(lua_tostring(L, i), lua_strlen(L, i));

    case LUA_TTABLE:
      return table_ref(L, lua_gettop(L));
    /*
    case LUA_TFUNCTION:
      *dopop = 0;
      return func_ref(L);
    */
    default:
	    abort();
  }
}

static int run_perl_func (lua_State *L) {
  lua_Object  *self         = (lua_Object*)lua_touserdata(L, lua_upvalueindex(1));
  RV          *func_params  = (RV*)lua_touserdata(L, lua_upvalueindex(2));
  char        *func_name    = lua_tostring(L, lua_upvalueindex(3));
  HV          *fp_deref     = (HV*)SvRV(func_params);

  int   flags, i, num_ret;
  char *context;

  dSP;

  /* Don't need to know 
   * a) the number of args we expect or
   * b) the number of return values
   * since Lua provisions for variable both, like Perl does.
   */
  context   = (char*)SvPV(*(hv_fetch(fp_deref, "context",  7, 0)));

  flags = strtoflags(context);

  if (lua_gettop(L) == 0) 
    flags |= G_NOARGS;

  if (flags & G_VOID) 
    flags |= G_DISCARD;

  ENTER;
  SAVETMPS;

  flags |= strtoflags(context);

  PUSHMARK(SP);
  /* The stack should now be the right size. */
  for (i = 1; i <= lua_gettop(L); ++i) {
    XPUSHs(sv_2mortal(perl_from_lua_val(self, i)));
  }
  PUTBACK;
  num_ret = call_pv(func, flags);

  SPAGAIN;

  for(i = 0; i < num_ret; ++i) {
    lua_push_perl_var(L, POPs);
  }

  PUTBACK;
  /* TODO:
     Convert the Perl values returned from the Perl function back into
     Lua values, and push them back on the stack.
  */

  FREETMPS;
  LEAVE;

	return num_return_vals;
}

static int run_perl_func_ref (lua_State *L) {
  lua_Object *self = (lua_Object*)lua_touserdata(L, lua_upvalueindex(1));
  CV         *func = (CV*)        lua_touserdata(L, lua_upvalueindex(2));
  char       *func_name   = lua_tostring(L, lua_upvalueindex(3));

  /* TODO */
}

int strtoflags(char *str) {
  int flags = 0;

  if(!strcmp(str, "void")) {
    flags = G_VOID;
  }
  else if(!strcmp(str, "list") or !strcmp(str, "array")) {
    flags = G_ARRAY;
  }
  else if(!strcmp(str, "scalar")) {
    flags = G_SCALAR;
  }

  return flags;
}

MODULE = Outline::Lua		PACKAGE = Outline::Lua

PROTOTYPES: ENABLE

Outline::Lua
new()
  PREINIT:
    lua_Object *self;
  INIT:
    Newx(self, 1, lua_Object);
    self->L = lua_open();
  CODE:
    self->nil   = get_sv("Outline::Lua::nil", 1);
    self->error = NULL;
    self->funcs = newHV();
    RETVAL      = self;
  OUTPUT:
    RETVAL

/* Code receives the struct representing self and
 * the hashref when it is run. It also receives
 * the Lua name of the func, which is the key to
 * the hashref.
 */

void 
_add_func(self, lua_name, func_params_ref)
  Outline::Lua self;
  SV *lua_name;
  RV *func_params_ref;
  PREINIT:
    char *lua_name_str;
  CODE:
    lua_name_str = SvPV_nolen(lua_name);

    lua_pushlightuserdata(self->L, self);
    lua_pushlightuserdata(self->L, func_params_ref);
    lua_pushstring(self->L, lua_name_str);
    lua_pushcclosure(self->L, &run_perl_func, 3);
    lua_setglobal(self->L, lua_name_str);

void
_add_code_ref(self, func, func_params_ref)
  Outline::Lua self;
  CV *func;
  RV *func_params_ref;
  PREINIT:
    char *lua_name_str;
  CODE:
    lua_name_str = SvPV_nolen(lua_name);

    lua_pushlightuserdata(self->L, self);
    lua_pushlightuserdata(self->L, func);
    lua_pushstring(self->L, lua_name_str);
    lua_pushcclosure(self->L, &run_perl_func_ref, 2);
    lua_setglobal(self->L, lua_name_str);

 #int
 #run(self, code)
 #  Outline::Lua self;
 #  SV *code;
 #  PREINIT:
 #    int error;
 #    STRLEN code_length;
 #    char *codestr;
 #    
 #  CODE:
 #    /* TODO
 #    *
 #    * SV *error_func;
 #    * char *error_func_name;
 #    * error_func_name = SvPV(error_func_name);
 #    *
 #    * If a perl func has been registered with this name, use it as the error func.
 #    */
 #    /* If this isn't real Lua code then you suck. */
 #    codestr = SvPV(code, code_length);
 #
 #    /* Give it to Lua */
 #    error = luaL_loadbuffer(self->L, codestr, code_length, "LUA_OBJECT_RUN") ||
 #            lua_pcall(self->L,0,0,0);
 #    /* See what happens */
 #    RETVAL = error;
 #    self->error = lua_tostring(self->L, -1);
 #
 #  OUTPUT:
 #    RETVAL


void
DESTROY(self)
  Outline::Lua self
  CODE:
    lua_close(self->L);
    Safefree(self);

