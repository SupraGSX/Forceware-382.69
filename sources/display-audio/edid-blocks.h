/* Independent Windows capability projection; no upstream private structures. */
typedef unsigned int U;
typedef unsigned char B;
#define SNAPSHOT_MAX 2048U
#define SAD_MAX 15U
#define GOOD 0U
#define INVALID 1U
#define INCOMPLETE 2U
#define TOO_LARGE 3U
#define OVERFLOW 4U
#define UNAVAILABLE 5U
struct Caps {
 U status, audio_status, blocks, cta, basic, count, legacy, forum, conflict;
 U legacy_len, forum_len, tmds, scdc;
 B sads[45], speakers[3], vendor[31], hf[31], primary[107];
};
void clearBytes(void*,U);
U parseEdid(const B*,U,struct Caps*);
void audioSummary(const struct Caps*,B*);
