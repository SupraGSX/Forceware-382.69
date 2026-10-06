/* A passive ceiling is not proof of training. Active mode preparation must
 * use a successfully trained pair, including after an unsuccessful probe. */
typedef unsigned int u32;
extern u32 best_pair(u32,u32,u32);
u32 query_pair(u32 passed,u32 rate,u32 lanes,u32 active) {
 u32 pair=best_pair(passed,rate,lanes);
 if(pair || active || (passed&255U)) return pair;
 if((rate!=6 && rate!=10 && rate!=20 && rate!=30) ||
    (lanes!=1 && lanes!=2 && lanes!=4)) return 0;
 return (rate<<8)|lanes;
}
