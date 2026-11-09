/* XP power-policy serialization for the 391.35 firmware interface. */
typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
#define STDCALL __attribute__((stdcall))
#define B(p,o) (*(u8 *)((u8 *)(p)+(o)))
#define W(p,o) (*(u16 *)((u8 *)(p)+(o)))
#define D(p,o) (*(u32 *)((u8 *)(p)+(o)))
typedef u32 (STDCALL *serialize)(void *,void *,void *);
/* Native4C1968 is called by policy constructor4C19D4 before374F82 writes
 * power141C. This draft reconstructs that initial zero-selector query using
 * XP clock-object fields. Runtime ordering must still be confirmed. */
static u32 initial_clock_mask(void *clk,u32 *result)
{
 u32 mask=D(clk,0x1ee0),selected=D(clk,0x201c),count=B(clk,0x1ef0);
 u32 *array=(u32 *)D(clk,0x1ee8),i,value=0,gpc=0;
 if(!count || count>32 || !array || (count<32 && (mask>>count)) ||
    (selected&~mask) || !selected)return 0x1f;
 for(i=0;i<count;i++)if(selected&(1u<<i)){
  void *o=(void *)array[i];u32 deps,domain;
  if(!o || B(o,0)!=4 || B(o,1)!=i)return 0x1f;
  deps=D(o,0xb8);domain=D(o,0x24);
  if(deps&~mask)return 0x1f;
  if(domain==0x10000)gpc++;
  if(domain && domain!=0x10000)value|=(1u<<i)|deps;
 }
 /* Only the mapped GP108 separate-GPC-domain layout is accepted. */
 if(gpc!=1 || !value)return 0x1f;
 *result=value;return 0;
}
typedef u8 (STDCALL *is_type)(void *,void *,void *,u32);

static void mask_header(void *out,u32 mask)
{
 u32 n=0,t=mask;while(t){n++;t>>=1;}
 B(out,0)=1; B(out,2)=n; D(out,4)=mask;
}

static u32 validate(void *group,u32 kind)
{
 u32 i,mask=D(group,0),count=B(group,0x10),*a=(u32 *)D(group,8);
 if(count>32 || (mask && (!count || !a)) || (count<32 && (mask>>count)))return 0x1f;
 for(i=0;i<count;i++)if(mask&(1u<<i)){
  void *obj=(void *)a[i];u32 type;
  if(!obj || !D(obj,0x10))return 0x1f;
  type=B(obj,0);
  if(kind==0){
   if(type!=0 && type!=3 && type!=11)return 0x1f;
   if(D(obj,0x1b0)>3 || D(obj,0x1b4)>255 || (!D(obj,0x1b0)&&D(obj,0x1b4)) || !D(obj,0x1b8))return 0x1f;
   if(type==11 && (B(obj,0x1f5)>1 || B(obj,0x1fc)==255))return 0x1f;
  }else if(kind==1 || kind==2){if(type!=0)return 0x1f;}
  else return 0x1f; /* Unknown subgroup remains unsupported. */
 }
 return 0;
}

u32 STDCALL gp108_power_class2(void *gpu,void *power,void *out)
{
 u8 *g=(u8 *)power+0x10f8,*a=(u8 *)power+0x1214,*z=(u8 *)power+0x1330;
 u32 mask=D(g,0),excluded=D(power,0x10b8),special=0,i,j,status;
 u32 *objects=(u32 *)D(g,8),clock_mask;u8 old[80];
 void *clk=(void *)D(gpu,0x1634);
 if(validate(g,0)||validate(a,1)||validate(z,2))return 0x1f;
 if(!clk || !D(clk,0x1ee8) || B(clk,0x1ef0)>32 || !B(clk,0x1ef0))return 0x1f;
 status=initial_clock_mask(clk,&clock_mask);if(status)return status;
 for(i=0;i<2;i++){
  u32 index=B(power,0x10c8+i);
  if(index<32 && (mask&(1u<<index))){
   void *obj=(void *)objects[index];
   if(((is_type)D(obj,0x1b8))(gpu,power,obj,0xfd))special|=1u<<index;
  }
 }
 mask_header(out,mask&~excluded);
 B(out,8)=B(power,0x10a0); B(out,9)=B(power,0x10a1); B(out,10)=B(power,0x10f4);
 for(i=0;i<7;i++)B(out,11+i)=B(power,0x10c4+i);
 B(out,18)=255;B(out,19)=255; /* new optional header indices absent in XP */
 W(out,20)=W(power,0x10f0);W(out,22)=W(power,0x10f2);
 D(out,24)=D(power,0x10a4)&~excluded;
 D(out,28)=D(power,0x10a4)&~special;
 D(out,32)=D(power,0x10a4)&special;
 D(out,36)=D(power,0x10a8)&~excluded;
 D(out,40)=D(power,0x10ac)&~excluded;
 D(out,44)=D(power,0x10b0)&~excluded;
 D(out,48)=D(power,0x10bc);D(out,52)=D(power,0x10c0);
 D(out,56)=0x1000; /* native GP108 GPC domain identifier, not a clock rate */
 for(i=0;i<32;i++)if((mask&~excluded)&(1u<<i)){
  void *obj=(void *)objects[i];u8 *e=(u8 *)out+64+i*64;
  for(j=0;j<80;j++)old[j]=0;
  status=((serialize)D(obj,0x10))(gpu,obj,old);if(status)return status;
  e[0]=old[0];for(j=1;j<=4;j++)e[j+1]=old[j];for(j=8;j<26;j++)e[j]=old[j];
  /* Exact391 common serializer47449C writes its two-byte filterInfo at1A/1B.
   * Stock XP718EB0 emits the equivalent DWORD fields at1C/20. */
  e[26]=(u8)D(obj,0x1b0);e[27]=(u8)D(obj,0x1b4);
  if(B(obj,0)==0){for(j=0;j<12;j++)e[28+j]=old[36+j];}
  else if(B(obj,0)==3){for(j=0;j<3;j++)e[28+j]=old[36+j];}
  else{
   for(j=0;j<12;j++)e[28+j]=old[36+j];
   e[40]=B(obj,0x1f5);e[41]=0;e[42]=old[52];e[43]=old[60];
   W(e,44)=W(old,48);W(e,46)=W(old,50);D(e,48)=clock_mask;
   for(j=0;j<4;j++)e[52+j]=old[61+j];
  }
 }
 for(i=0;i<2;i++){
  u8 *group=i?z:a,*header=(u8 *)out+(i?0xc50:0x840);
  u32 m=D(group,0),*array=(u32 *)D(group,8),stride=i?16:32;
  mask_header(header,m);
  for(j=0;j<32;j++)if(m&(1u<<j)){
   void *obj=(void *)array[j];
   /*3915A5BA2/4D9E7E: association index1->2, weightWORD2->4.*/
   for(u32 k=0;k<80;k++)old[k]=0;
   status=((serialize)D(obj,0x10))(gpu,obj,old);
   if(status)return status;
   u8*e=header+16+stride*j;
if(!i){e[0]=old[0];e[2]=old[1];e[4]=old[2];e[5]=old[3];}
else{
 /* Native3915A5D56/4DA400: XP event index becomes EVENT0 plus index.
  * sample multiplier2->4, targetWORD4->6; PROPGAIN tail8..D retained. */
 e[0]=old[0];e[1]=0;e[2]=0;e[3]=old[1];e[4]=old[2];e[5]=0;
 W(e,6)=W(old,4);for(u32 k=8;k<14;k++)e[k]=old[k];e[14]=0;e[15]=0;
}
  }
 }
 return 0;
}
