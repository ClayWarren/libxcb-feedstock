#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xcb/xcb.h>
#include <xcb/xcbext.h>
#include <xcb/render.h>

#define CHECK(x) do { if (!(x)) { fprintf(stderr, "Failed: %s (line %d)\n", #x, __LINE__); return 1; } } while (0)

int main(int argc, char **argv)
{
    static const struct { const char *name, *host; int display, screen; } valid[] = {
        {":0", "", 0, 0}, {":1.2", "", 1, 2},
        {"x.org:0", "x.org", 0, 0}, {"198.112.45.11:0.1", "198.112.45.11", 0, 1},
        {"::1:0.1", "::1", 0, 1}, {"[::1]:0.1", "[::1]", 0, 1},
        {"hydra::0.1", "hydra:", 0, 1}
    };
    static const char *invalid[] = {"", ":", "::", ":::0.", ":a", ":0.a", ":0.0.", "localhost", "127.0.0.1:"};
    size_t i;
    for (i = 0; i < sizeof(valid) / sizeof(valid[0]); ++i) {
        char *host = NULL;
        int display = -1, screen = -1;
        CHECK(xcb_parse_display(valid[i].name, &host, &display, &screen));
        CHECK(strcmp(host, valid[i].host) == 0);
        CHECK(display == valid[i].display && screen == valid[i].screen);
        free(host);
    }
    for (i = 0; i < sizeof(invalid) / sizeof(invalid[0]); ++i) {
        char *host = NULL;
        int display = -1, screen = -1;
        CHECK(!xcb_parse_display(invalid[i], &host, &display, &screen));
        CHECK(host == NULL && display == -1 && screen == -1);
    }
    for (i = 0; i < 32; ++i) {
        CHECK(xcb_popcount(UINT32_C(1) << i) == 1);
    }
    CHECK(xcb_popcount(UINT32_MAX) == 32);
    CHECK(strcmp(xcb_render_id.name, "RENDER") == 0);
    CHECK(argc == 2);
    {
        xcb_auth_info_t auth = {0, NULL, 0, NULL};
        xcb_connection_t *c = xcb_connect_to_display_with_auth_info(argv[1], &auth, NULL);
        xcb_get_input_focus_reply_t *focus;
        xcb_render_query_version_reply_t *render;
        xcb_generic_error_t *error = NULL;
        uint32_t id;
        CHECK(c != NULL && xcb_connection_has_error(c) == 0);
        CHECK(xcb_get_setup(c)->protocol_major_version == 11);
        id = xcb_generate_id(c);
        CHECK((id & UINT32_C(0xfff00000)) == UINT32_C(0x00200000));
        focus = xcb_get_input_focus_reply(c, xcb_get_input_focus(c), &error);
        CHECK(error == NULL && focus != NULL);
        CHECK(focus->focus == UINT32_C(0x12345678));
        free(focus);
        render = xcb_render_query_version_reply(c, xcb_render_query_version(c, 0, 11), &error);
        CHECK(error == NULL && render != NULL);
        CHECK(render->major_version == 0 && render->minor_version == 11);
        free(render);
        CHECK(xcb_connection_has_error(c) == 0);
        xcb_disconnect(c);
    }
    {
        xcb_connection_t *bad = xcb_connect("not-a-display", NULL);
        CHECK(bad != NULL);
        CHECK(xcb_connection_has_error(bad) == XCB_CONN_CLOSED_PARSE_ERR);
        xcb_disconnect(bad);
    }
    puts("PASS: display parsing, popcount, DLL extension data, TCP X11 setup, core reply and Render round-trip");
    return 0;
}
