#ifndef WINLISP_H
#define WINLISP_H

#if defined(BOS) || defined(NHSTDC)
#define DIMENSION_P int
#else
# ifdef WIDENED_PROTOTYPES
#define DIMENSION_P unsigned int
# else
#define DIMENSION_P Dimension
# endif
#endif

extern struct window_procs tty_procs;

/* ### winlisp.c ### */
extern void win_lisp_init(int);
extern void lisp_init_nhwindows(int *, char **);
extern void lisp_player_selection(void);
extern void lisp_askname(void);
extern void lisp_get_nh_event(void);
extern void lisp_exit_nhwindows(const char *);
extern void lisp_suspend_nhwindows(const char *);
extern void lisp_resume_nhwindows(void);
extern winid lisp_create_nhwindow(int);
extern void lisp_clear_nhwindow(winid);
extern void lisp_display_nhwindow(winid, boolean);
extern void lisp_destroy_nhwindow(winid);
extern void lisp_curs(winid, int, int);
extern void lisp_status_update(int, genericptr_t, int, int, int, unsigned long *);
extern void lisp_putstr(winid, int, const char *);
extern void lisp_display_file(const char *, boolean);
extern void lisp_start_menu(winid, unsigned long);
extern void lisp_add_menu(winid, const glyph_info *, const ANY_P*,
			              char, char, int, int, const char *, unsigned);
extern void lisp_end_menu(winid, const char *);
extern int lisp_select_menu(winid, int, menu_item **);
extern char lisp_message_menu(char, int, const char *);
extern void lisp_update_inventory(int);
extern void lisp_mark_synch(void);
extern void lisp_wait_synch(void);
#ifdef CLIPPING
extern void lisp_cliparound(int, int);
#endif
#ifdef POSITIONBAR
extern void lisp_update_positionbar(char *);
#endif
extern void lisp_print_glyph(winid, coordxy, coordxy, const glyph_info*, const glyph_info*);
extern void lisp_raw_print(const char *);
extern void lisp_raw_print_bold(const char *);
extern int lisp_nhgetch(void);
extern int lisp_nh_poskey(coordxy *, coordxy *, int *);
extern void lisp_nhbell(void);
extern int lisp_doprev_message(void);
extern char lisp_yn_function(const char *, const char *, char);
extern void lisp_getlin(const char *, char *);
extern int lisp_get_ext_cmd(void);
extern void lisp_number_pad(int);
extern void lisp_delay_output(void);

extern win_request_info * lisp_ctrl_nhwindow(winid, int, win_request_info *);

#endif /* WINLISP_H */
