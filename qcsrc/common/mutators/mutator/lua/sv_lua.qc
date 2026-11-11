// SPDX-License-Identifier: GPL-3.0-or-later
// Insanotic: Lua server plugins, game side. See docs/MODDING.md.
#include "sv_lua.qh"

bool Lua_Available()
{
	if (!autocvar_g_lua)
		return false;
	if (!checkextension("XON_LUA"))
	{
		LOG_INFO("g_lua is set but this engine lacks the XON_LUA extension; Lua plugins are disabled");
		return false;
	}
	return true;
}

// The mutator is only added when g_lua is on, so with g_lua 0 no hook gains
// a callback and gameplay is exactly stock. g_lua is read at map start.
REGISTER_MUTATOR(lua, Lua_Available())
{
	MUTATOR_ONADD
	{
		Lua_ReloadPlugins();
	}
	return false;
}

/** reads the numeric "order" value of a flat plugin.json; 0 when absent */
float Lua_PluginOrder(string dir)
{
	int fh = fopen(strcat(dir, "/plugin.json"), FILE_READ);
	if (fh < 0)
		return 0;
	string json = "";
	string l;
	while ((l = fgets(fh)))
		json = strcat(json, l, " ");
	fclose(fh);
	int p = strstrofs(json, "\"order\"", 0);
	if (p < 0)
		return 0;
	p = strstrofs(json, ":", p);
	if (p < 0)
		return 0;
	return stof(substring(json, p + 1, 32));
}

string lua_plugin_path[LUA_MAX_PLUGINS];
float lua_plugin_order[LUA_MAX_PLUGINS];

void Lua_ReloadPlugins()
{
	if (!MUTATOR_lua.m_added)
	{
		LOG_INFO("Lua plugins are off on this map (set g_lua 1 and restart the map)");
		return;
	}

	int n = 0;
	int h = search_begin("plugins/*/init.lua", true, true);
	if (h >= 0)
	{
		int total = search_getsize(h);
		for (int i = 0; i < total; ++i)
		{
			if (n >= LUA_MAX_PLUGINS)
			{
				LOG_INFOF("too many Lua plugins, only the first %d are loaded", LUA_MAX_PLUGINS);
				break;
			}
			string path = search_getfilename(h, i);
			float order = Lua_PluginOrder(substring(path, 0, strlen(path) - strlen("/init.lua")));
			// insertion sort by (order, path)
			int j = n;
			while (j > 0 && (lua_plugin_order[j - 1] > order || (lua_plugin_order[j - 1] == order && strcmp(lua_plugin_path[j - 1], path) > 0)))
			{
				lua_plugin_path[j] = lua_plugin_path[j - 1];
				lua_plugin_order[j] = lua_plugin_order[j - 1];
				--j;
			}
			lua_plugin_path[j] = path;
			lua_plugin_order[j] = order;
			++n;
		}
		search_end(h);
	}

	int ok = 0;
	for (int i = 0; i < n; ++i)
	{
		if (lua_load(lua_plugin_path[i]))
			++ok;
		lua_plugin_path[i] = string_null; // temp strings, do not keep them around
	}
	LOG_INFOF("Lua: %d of %d plugins loaded", ok, n);
}
