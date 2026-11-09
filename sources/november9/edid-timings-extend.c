/* Bounded monitor enumeration extension; native filtering remains downstream. */
typedef unsigned int U;typedef unsigned short W;typedef unsigned char B;
#define S __attribute__((stdcall))
#define D(p,o) (*(U*)((B*)(p)+(o)))
extern U S nativePrimary644(const B*,U,B*,U);
extern U S nativeParse644(const B*,U,B*);
extern B* S alloc644(U,U,U);extern void S free644(void*);
extern U S convert643(const B*,B*,U,U);
static U valid(const B*e,U n){
 U k,j,s,blocks,pos,end,len;if(!e||n<256||n>512)return 0;
 if(e[0]||e[7])return 0;for(j=1;j<7;j++)if(e[j]!=255)return 0;
 blocks=(U)e[126]+1;if(blocks<2||blocks>4||blocks*128>n)return 0;
 for(k=0;k<blocks;k++){s=0;for(j=0;j<128;j++)s+=e[k*128+j];if(s&255)return 0;}
 for(k=1;k<blocks;k++){const B*b=e+k*128;
  if(b[0]==2){end=b[2];if(!end)continue;if(end<4||end>127)return 0;for(pos=4;pos<end;){len=b[pos]&31;j=b[pos]>>5;pos++;if(len>end-pos)return 0;if(j==3&&len<3)return 0;if(j==7&&!len)return 0;pos+=len;}}
  else if(b[0]==0x70){if(b[2]>121)return 0;end=5+b[2];s=0;for(j=1;j<=end;j++)s+=b[j];if(s&255)return 0;for(pos=5;pos<end;){for(j=pos;j<end&&!b[j];j++);if(j==end)break;if(end-pos<3)return 0;len=b[pos+2];if(len>end-pos-3)return 0;if(b[pos]==3&&((b[pos+1]&7)!=1||!len||len%20))return 0;pos+=3+len;}}
 }return blocks;
}
static U svd(const B*e,U blocks,U vic){
 U k,pos,end,len,tag,j;for(k=1;k<blocks;k++){const B*b=e+k*128;if(b[0]!=2||b[1]<3)continue;end=b[2];if(end<4||end>127)continue;
 for(pos=4;pos<end;){tag=b[pos]>>5;len=b[pos]&31;pos++;if(len>end-pos)break;if(tag==2)for(j=0;j<len;j++)if((b[pos+j]&127)==vic)return 1;pos+=len;}}
 return 0;
}
static U type1(const B*e,U blocks){U k,p,end,n;for(k=1;k<blocks;k++){const B*b=e+k*128;if(b[0]!=0x70||b[2]>121)continue;end=5+b[2];if(end>127)continue;for(p=5;p+3<=end;){n=b[p+2];if(n>end-p-3)break;if(b[p]==3&&(b[p+1]&7)==1&&n>=20&&n%20==0)return 1;p+=3+n;}}return 0;}
U S extend644(const B*e,U bytes,B*out,U mask){
 U result=nativePrimary644(e,bytes,out,mask),blocks,i,j,k,count,seq,origin,status,vic,dupe;B*info;B row[84];
 if(!result||!out||(blocks=valid(e,bytes))==0||D(out,0)>=64)return result;
 info=alloc644(0,0x3990,0x494d564e);if(!info)return result;
 if(nativeParse644(e,blocks*128,info)!=0)goto done;
 count=D(info,0x3298);if(count>128)goto done;
 for(i=0;i<count&&D(out,0)<64;i++){
  const B*n=info+0x98+i*100;status=D(n,56);vic=status&255;origin=0;seq=0;
  if((status&0xff00)==0xd00&&vic>34&&vic<=107&&svd(e,blocks,vic)){origin=13;seq=vic;}
  else if((status&0xff00)==0x1900&&type1(e,blocks)){
   origin=9;seq=1;for(j=0;j<D(out,0);j++){U f=D(out+4+j*84,8);if((f>>16)==9&&(f&65535)>=seq)seq=(f&65535)+1;}
  }
  if(!origin||!convert643(n,row,origin,seq))continue;
  dupe=0;for(j=0;j<D(out,0);j++){B*r=out+4+j*84;for(k=0;k<32&&r[44+k]==row[44+k];k++);if(k==32){dupe=1;break;}}
  if(dupe)continue;
  B*r=out+4+D(out,0)*84;for(k=0;k<84;k++)r[k]=row[k];D(out,0)++;
 }
 done:free644(info);return result;
}
