#include <stdio.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main (void) {
	char buff[256];
	int error;
	lua_State *L = lua_open();   /* opens Lua */
	luaL_openlibs(L);            /* predefined functions - Perl will create its own, instead. */

	while (fgets(buff, sizeof(buff), stdin) != NULL) {             /* get a line of code */
		error = luaL_loadbuffer(L, buff, strlen(buff), "line") ||    /* compile the code in buff using L and return 0 if no error. */
						lua_pcall(L, 0, 0, 0);                               /* run the code in L */
		if (error) {                                                 /* The return value is a true value, and the error message is in L */
			fprintf(stderr, "%s", lua_tostring(L, -1));                /* tostring turns that error into a string here. */
			lua_pop(L, 1);                                             /* pop error message from the stack */
		}
	}

	lua_close(L);                /* clean up */
	return 0;
}

