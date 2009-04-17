#include <stdio.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>


lua_State *L;

static int run_perl_func (lua_State *L) ;
int register_perl_func( char *func, char *lua_name, int num_args, int num_ret ) ;


/* This is to be called from Perl, so I'll make it
   XS at some point. This is one of them skellington
   things at the moment.
*/
int register_perl_func( char *func, char *lua_name, int num_args, int num_ret ) {
	/* TODO: Is it better to use a Perl hash to store num_args and num_ret?
     Or keep it as part of the closure? Not decided yet. */

  /* here we store the Perl function's name as part of the closure, but
     register it to Lua using the lua_name. That is because the Perl
     version will have :: in it. */
	lua_pushstring(L, func);
  lua_pushnumber(L, num_args);
  lua_pushnumber(L, num_ret);
  lua_pushcclosure(L, &run_perl_func, 3);
	lua_setglobal(L, lua_name);

  /* L's stack should now be the same as it was on entry */
}

/* This is a closure. Its first argument should be the
   string name of the perl function that it was created with.
   Its second argument is the number of arguments the
   function expects. The third is the number of return values.
   This will be the case if it was created with register_perl_func 
*/
static int run_perl_func (lua_State *L) {
	const char *func = lua_tostring(L, lua_upvalueindex(1));
	int num_expected_args = (int)lua_tonumber(L, lua_upvalueindex(2));
	int num_return_vals = (int)lua_tonumber(L, lua_upvalueindex(3));

	if (!strcmp( func, "stuff" ) ) {
		lua_pushnumber(L, 1);
	}
	/* Magic goes here. */

	/* TODO:
     Convert the Lua values at the top of the stack into Perl values.

     Run the perl function with those converted values

     Convert the Perl values returned from the Perl function back into
     Lua values, and push them back on the stack.
  */

	return num_return_vals;
}

/* This needs to be replaced with whatever it is in XS that
   constitutes 'setup'. Currently it's main so I can see that
   it runs.

   I haven't learned enough XS yet, you see.
*/
int main (void) {
	char* buff;
	int error;
	L = lua_open();   /* L is global woo */
	luaL_openlibs(L);            /* TODO: remove this for the XS version and let Perl register its own print() etc */

	
	register_perl_func( "stuff", 1, 1 );

	buff = "print(stuff())";
	error = luaL_loadbuffer(L, buff, strlen(buff), "line") ||    /* compile the code in buff using L and return 0 if no error. */
					lua_pcall(L, 0, 0, 0);                               /* run the code in L */
	if (error) {                                                 /* The return value is a true value, and the error message is in L */
		fprintf(stderr, "%s", lua_tostring(L, -1));                /* tostring turns that error into a string here. */
		lua_pop(L, 1);                                             /* pop error message from the stack */
	}

	lua_close(L);                /* clean up */
	return 0;
}

