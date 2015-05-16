/* This program converts VENUS trajectory data into a format which
   is understood by VMD.
*/

#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#define MAX_ATOMS 6000

int qfirst, com1;
FILE *input,  *psf, *xmol;

void main (int argc, char *argv[])
{  
  int nts;
  int i, j, natom, n1, nlin1=0, m, nlin2;
  double delta;
  char atom[MAX_ATOMS][6],  atype[MAX_ATOMS][3];
  char atomnames[MAX_ATOMS];
  char hdr[5], segid[5], resid[5];
  char chaoxmol[35], chaopsf[35]; 
  char cf;
  double x[MAX_ATOMS], y[MAX_ATOMS], z[MAX_ATOMS];
  double amass=99.0, charge=999.0;
  char str[400];
  int nres=1,ch;
  int nocup=0;
  long desired_trajectory, current_line=1,trajectory;
  
  qfirst=1; 
  strcpy(hdr,  "CORD");
  strcpy(atype[0],  "NT");
  for (i=1;i<156;i++) strcpy(atype[i], "SE");
  for (i=156;i<MAX_ATOMS;i++) strcpy(atype[i], "NT");
  
  strcpy(resid, "Atom");
  strcpy(segid, "SEG1");
  
  if (argc != 4) {
     printf("usage:\n vmdx <inputfile> <outputfile> <trajectory #>\n");
     exit(1);
  }
  
  if ((input=fopen(argv[1], "r"))==NULL) {
      printf("Cannot open input file \n");
      exit(1);
  }
  
  strcpy (chaoxmol, argv[2]);
  strcpy (chaopsf, argv[2]);
  strcat (chaoxmol, ".xmol");
  strcat (chaopsf, ".psf");
  desired_trajectory=atoi(argv[3]);
  
  do {
    if (((ch=getc(input))=='S')||(ch=='s')){
      if (((ch=getc(input))=='Y')||(ch=='y')){
        fscanf(input,"%*s %*s %*s %*s %d",&trajectory);
        if (trajectory==desired_trajectory) nlin1=current_line;
        if (trajectory==(desired_trajectory+1)) {
          nlin2=current_line;
          break;
        }
      }
    }
    if (ch=='\n') current_line++;
  } while (!feof(input));

  if ((feof(input))&&!nlin1) {
    printf("Trajectory %d was not found in %s\n",desired_trajectory,argv[1]);
    exit(1);
  } 
  if ((feof(input))&&(nlin1)) nlin2=current_line;

  rewind(input);
  for (i=1;i<=(nlin1);i++) {do {ch=getc(input);} while (ch-'\n');}
  fscanf(input, "%d", &natom);
  do { ch= getc(input);}while (ch-'\n');
 
  for (i=0;i<natom;i++){ 
    fscanf(input, "%*d %*d %*f %*f %*f %2s", atom[i]);
    //atomnames[i]=atom[i];	
  }
  fscanf(input, "%d", &n1);
    do { ch= getc(input);}while (ch-'\n');
  for (i=1;i<=n1;i++){do{ch= getc(input);}while (ch-'\n');}
  do { ch= getc(input);}while (ch-'\n');
  do { ch= getc(input);}while (ch-'\n');
  fscanf(input, " %*s %*c %*d %*s %*s %*c %lf", &delta);
  do {ch=getc(input);} while ((ch - 'X')&&(ch-'x'));
    
  if ((xmol=fopen(chaoxmol, "w"))==NULL) {
      printf("Cannot open xmol file \n");
      exit(1);
  }
  nts=((nlin2-nlin1-1-natom-7-n1)/(natom+1));
  for (i=0; i<nts; i++) {
    do {ch=(getc(input));} while ((ch-'X')&&(ch-'x'));
    do {ch=getc(input);} while (ch-'\n');    
    fprintf(xmol,"%d\n",natom);
    fprintf(xmol,"%d\n",i);
    for (j=0; j<natom;j++){
      fscanf(input, "%lf %lf %lf", &x[j], &y[j], &z[j]);
      fprintf(xmol,"%s %lf %lf %lf \n",atom[j],x[j],y[j],z[j]);	
    }
  }
fclose(xmol);

}
