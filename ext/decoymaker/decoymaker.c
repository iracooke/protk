#include <ruby.h>
/*                                                                                                 */
/* make_random.c - make random protein sequence database using Markov chain with transitional      */
/* probabilities from amino acid frequencies in a real database in FASTA format                    */
/*                                                                                                 */
/* (c) Magnus Palmblad, Division of Ion Physics, Uppsala University, Sweden, 2001-                 */ 
/*                                                                                                 */
/* Usage: make_random <sequence database> <number of sequences to generate> <output file>          */
/*                                                                                                 */
/* Example: mmpi 562.fasta 1000000 562_random_1000000.fasta                                        */
/*                                                                                                 */
/* Compile with gcc -o make_random make_random.c -lm                                               */
/*                                                                                                 */

#include <stdio.h>
#include <stdlib.h>  
#include <ctype.h>
#include <string.h>
#include <math.h>

#define AMINO_ACIDS "ARNDCEQGHILKMFPSTWYV"
#define NOT_AMINO_ACIDS "BJOUXZ*"
#define MAX_SEQUENCE_LENGTH 20000
#define MAX_LINE_LENGTH 20000 /* large enough to read in long header lines */


static VALUE decoymaker_make_decoys(VALUE self,VALUE input_file_in,
  VALUE db_length_in,VALUE output_file_in,char *prefix_string_in) {
  
  char *input_file = RSTRING_PTR(input_file_in);
  long sequences_to_generate = NUM2INT(db_length_in);
  char * output_file = RSTRING_PTR(output_file_in);

  char line[MAX_LINE_LENGTH];      
  char settings_line[60][70];
  char infile[255], outfile[255]; /* for reading input and writing output */
  char prefix_string[255];
  char *p,**index;
  char *sequence; 
  char one_sequence[MAX_SEQUENCE_LENGTH],random_sequence[(int)(MAX_SEQUENCE_LENGTH*1.5)],random_sequence_output[(int)(MAX_SEQUENCE_LENGTH*1.5)];
  char *temp_sequence;
  int a;
  FILE *inp, *outp;

  long i, j, k, l, n, n_sequences, protein;
  long MP[21][MAX_SEQUENCE_LENGTH];
  long measured_aa_freq[21], generated_aa_freq[21], measured_pl_sum=0, generated_pl_sum=0;
  long row_sum[MAX_SEQUENCE_LENGTH],partial_sum;
  long one_index,pl;
  double x;

  /* scanning sequence database */
  
  strcpy(infile,input_file);

  if ((inp = fopen(infile, "r"))==NULL) {
    printf("error opening sequence database %s\n",infile);return -1;
  }

  printf("scanning sequence database \n%s\n",infile);
  fflush(stdout);

  i=0;n=0;k=0;

  while (fgets(line, MAX_LINE_LENGTH, inp) != NULL) {
    i++; 
    if(line[0]=='>') {
      if (!(n%1000)) {
        printf(".");
        fflush(stdout); 
        n++;
      }
    } 
  }
  
  n_sequences=n;


  /* reading sequence database */      
  
  temp_sequence=(char*)calloc(sizeof(char),MAX_SEQUENCE_LENGTH);
  sequence=(char*)malloc(sizeof(char)*(i*80)); /* allocate enough memory for 80 characters per line in FASTA database */
  index=(char**)malloc(sizeof(char*)*n_sequences);
  index[0]=sequence; /* set first index pointer to beginning of first database sequence */
  
  if ((inp = fopen(infile, "r"))==NULL) {
    printf("error opening sequence database %s\n",infile);
    return -1;
  }

  printf("done\nreading sequence database \n%s\n",infile);
  fflush(stdout);    
  
  n=-1;
  strcpy(temp_sequence,"\0");
  
  while (fgets(line, MAX_LINE_LENGTH, inp) != NULL)
  { 
    if (strcmp(line,"\n")==0) {
      continue;
    }
    if (line[0]=='>') { 
      if (n>=0) { 
        if (!(n%1000)&&n>0) { 
          printf(".");fflush(stdout);
        }
        strcpy(index[n],temp_sequence);
        n++; index[n]=index[n-1]+sizeof(char)*strlen(temp_sequence);
        strcpy(temp_sequence,"\0");
      }
      else 
      {
        n++;
        strcpy(temp_sequence,"\0");
      }
    }
    else 
    {
      if ( (strlen(temp_sequence)+strlen(line))>=MAX_SEQUENCE_LENGTH ) continue; 
      strncat(temp_sequence,line,strlen(line)-1);
    }   
  }

  strcpy(index[n],temp_sequence);

  fclose(inp);

  n_sequences=n+1;

  printf("done [read %li sequences (%li amino acids)]\n",n_sequences,(int)(index[n_sequences-1]-index[0])/sizeof(char)+strlen(temp_sequence));fflush(stdout);

  measured_pl_sum=(int)(index[n_sequences-1]-index[0])/sizeof(char)+strlen(temp_sequence);



  /* generating Markov probabilities */

  printf("generating Markov probability matrix...");
  fflush(stdout);

  srand(time(0)); /* replace with constant to re-generate identical random databases */

  for(i=0;i<MAX_SEQUENCE_LENGTH;i++) {
    for(j=0;j<=20;j++) {
      MP[j][i]=0;
    }
  }
  for(j=0;j<=20;j++) {
    measured_aa_freq[j]=0;generated_aa_freq[j]=0;
  }

  for(protein=0;protein<n_sequences;protein++)
  {
    if (!(protein%1000)) {
      printf(".");
      fflush(stdout);
    }

    if (protein<(n_sequences-1)) 
    {
     strncpy(one_sequence,index[protein],(index[protein+1]-index[protein])/sizeof(char));
     one_sequence[(index[protein+1]-index[protein])/sizeof(char)]='\0';
   }
   else strcpy(one_sequence,index[protein]);
   pl=strlen(one_sequence);
   n=1;one_index=0;

   for(i=0;i<pl;i++)
   {
     if(strpbrk(NOT_AMINO_ACIDS,(const char *)&one_sequence)==NULL)
     {
      if ( strchr(AMINO_ACIDS,one_sequence[i])==NULL)
      {
        printf("Unknown amino acid %c",one_sequence[i]);                
      } else {
        a=20-strlen(strchr(AMINO_ACIDS,one_sequence[i])); // current amino acid
        MP[a][i]++;
        measured_aa_freq[a]++;
      }
  }
    else {
    a=floor(20*(float)rand()/RAND_MAX);
    MP[a][i]++; 
    measured_aa_freq[a]++;
    } // replace B, X, Z etc. with random amino acid to preserve size distribution
  }
  MP[20][pl]++;
      measured_aa_freq[20]++; // MP[20][n] is the number of sequences of length n in the database 
    }

    printf("done\n"); 
    fflush(stdout);

  

  for(i=0;i<MAX_SEQUENCE_LENGTH;i++){
     row_sum[i]=0;
  }
  
  for(i=0;i<MAX_SEQUENCE_LENGTH;i++){ 
    for(j=0;j<=20;j++){ 
      row_sum[i]+=MP[j][i];
    }
  }


  /* generate random protein sequences through Markov chain */

  strcpy(outfile,output_file);

    if ((outp = fopen(outfile, "w"))==NULL) {
      printf("error opening output file %s\n",outfile); 
      return -1;
    }

    printf("generating %li random protein sequences",sequences_to_generate);fflush(stdout);

    strcpy(prefix_string,RSTRING_PTR(prefix_string_in));

    for(protein=0;protein<sequences_to_generate;protein++)
    {
      if (!(protein%1000)) {
        printf(".");fflush(stdout);
      }
      
      i=0; j=0;
      while (1)
      {
       x=(double)row_sum[j]*((double)rand()/RAND_MAX);
       partial_sum=MP[0][j]; i=1;
       while (partial_sum<x) {partial_sum+=MP[i][j]; i++;}
    if (j>=MAX_SEQUENCE_LENGTH) i=21; /* terminate when sequence has reached MAX_SEQUENCE_LENGTH */
       if (i<21)
       {
         random_sequence[j]=AMINO_ACIDS[i-1];j++;generated_aa_freq[i-1]++;
       }
    else /* i==21, i.e. protein sequence terminated */
       {
         k=0; generated_aa_freq[20]++; generated_pl_sum+=j;
         for(l=0;l<j;l++) 
         {
          random_sequence_output[k]=random_sequence[l]; k++;
          if (!((k+1)%61))
          {
            random_sequence_output[k]='\n'; k++;
          }
        }

        random_sequence_output[k]='\0';
        if (!(k%61)) random_sequence_output[k-1]='\0'; /* remove extra newline for sequence length multiple of 60 */
        fprintf(outp,">%srp%li\n%s\n",prefix_string,protein,random_sequence_output);
        break;
      }
    }
  }
  
  fclose(outp);


  /* freeing some memory... */

  free(index);  
  
  printf("done (wrote %li random protein sequences to %s)\n",sequences_to_generate,outfile);

  k=0;l=0;
  for(i=0;i<=20;i++) {k+=measured_aa_freq[i];l+=generated_aa_freq[i];}
    // printf("<f(aa) in %s> <f(aa) in %s>\n",infile,outfile);
  // for(i=0;i<=20;i++) printf("%f %f\n",(float)measured_aa_freq[i]/k,(float)generated_aa_freq[i]/l);

  printf("<average sequence length in %s> = %f\n<average sequence length in %s> = %f\n",infile,measured_pl_sum/(float)n_sequences,outfile,generated_pl_sum/(float)sequences_to_generate);

  return 0;

}


void Init_decoymaker(void) 
{
  VALUE klass = rb_define_class("Decoymaker",rb_cObject);

  rb_define_singleton_method(klass,
    "make_decoys", decoymaker_make_decoys, 4);


}
