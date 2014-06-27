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
#define MAX_SEQUENCE_LENGTH 2000
#define MAX_LINE_LENGTH 200000 /* large enough to read in long header lines */

void RemoveSpaces(char* source)
{
  char* i = source;
  char* j = source;
  while(*j != 0)
  {
    *i = *j++;
    if(*i != ' ')
      i++;
  }
  *i = 0;
}


static VALUE decoymaker_make_decoys(VALUE self,VALUE input_file_in,
  VALUE db_length_in,VALUE output_file_in,VALUE prefix_string_in) 
{

  char *infile = StringValueCStr(input_file_in);
  long sequences_to_generate = NUM2INT(db_length_in);
  char * outfile = StringValueCStr(output_file_in);
  char *prefix_string = StringValueCStr(prefix_string_in);

  char line[MAX_LINE_LENGTH];      
  // char settings_line[60][70];

  char *p,**index;
  
  char one_sequence[MAX_SEQUENCE_LENGTH];
  char random_sequence[(int)(MAX_SEQUENCE_LENGTH*1.5)];
  char random_sequence_output[(int)(MAX_SEQUENCE_LENGTH*1.5)];
  char *temp_sequence;
  int a;
  FILE *inp, *outp;

  long i, j, k, l, n, n_sequences, protein;
  long MP[21][MAX_SEQUENCE_LENGTH];
  long measured_aa_freq[21], generated_aa_freq[21], measured_pl_sum=0, generated_pl_sum=0;
  long row_sum[MAX_SEQUENCE_LENGTH],partial_sum;
  long one_index,pl;
  double x;

  printf("1\n");

  /* scanning sequence database */
  printf("2\n");fflush(stdout);
  if ((inp = fopen(infile, "r"))==NULL) {
    printf("error opening sequence database %s\n",infile);return -1;
  }

  long total_sequence_len=0;
  n=0;
  printf("2.1\n");fflush(stdout);
  while (fgets(line, MAX_LINE_LENGTH, inp) != NULL) {
    total_sequence_len+=strlen(line);

    // printf("%ld\n",i);fflush(stdout);
    if (line[0]=='>') { n++; } 
  }
  
  printf("%ld\n",total_sequence_len);fflush(stdout);  
  
  n_sequences=n;


  /* reading sequence database */      
  
  temp_sequence=(char*)calloc(sizeof(char),MAX_SEQUENCE_LENGTH);

  char *sequence_block=(char*)malloc(sizeof(char)*(total_sequence_len+2));

  index=(char**)malloc(sizeof(char*)*n_sequences);
  index[0]=sequence_block; /* set first index pointer to beginning of first database sequence */
  
  if ((inp = fopen(infile, "r"))==NULL) {
    printf("error opening sequence database %s\n",infile);
    return -1;
  }

  n=-1;
  strcpy(temp_sequence,"\0");
  
  while (fgets(line, MAX_LINE_LENGTH, inp) != NULL)
  {
    RemoveSpaces(line);

    if (strcmp(line,"\n")==0) { // Skips blank lines
      continue;
    }

    if (line[0]=='>') { 
      if (n>=0) { 

        strcpy(index[n],temp_sequence);
        n++; 
        index[n]=index[n-1]+sizeof(char)*strlen(temp_sequence);
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
      if ( (strlen(temp_sequence)+strlen(line))>=MAX_SEQUENCE_LENGTH ) { 
        continue;
      } 
      strncat(temp_sequence,line,strlen(line)-1);
    }   
  }

  strcpy(index[n],temp_sequence);

  fclose(inp);

  n_sequences=n+1;

  // printf("done [read %li sequences (%li amino acids)]\n",n_sequences,(int)(index[n_sequences-1]-index[0])/sizeof(char)+strlen(temp_sequence));fflush(stdout);

  // measured_pl_sum=(int)(index[n_sequences-1]-index[0])/sizeof(char)+strlen(temp_sequence);





  /* generating Markov probabilities */

  // printf("generating Markov probability matrix...");
  // fflush(stdout);

  srand(time(0)); /* replace with constant to re-generate identical random databases */

  for(i=0;i<MAX_SEQUENCE_LENGTH;i++) {
    for(j=0;j<=20;j++) {
      MP[j][i]=0;
    }
  }
  for(j=0;j<=20;j++) {
    measured_aa_freq[j]=0;
    generated_aa_freq[j]=0;
  }


  for(protein=0;protein<n_sequences;protein++)
  {
    if (protein<(n_sequences-1)) 
    {
      long len_one_seq = (index[protein+1]-index[protein])/sizeof(char);
      if ( len_one_seq > MAX_SEQUENCE_LENGTH ){
        printf("Seq is longer than max len \n");fflush(stdout);
        len_one_seq=MAX_SEQUENCE_LENGTH;
      }
      strncpy(one_sequence,index[protein],len_one_seq);

      one_sequence[len_one_seq]='\0'; // NULL terminate the string

    } else { 
      strcpy(one_sequence,index[protein]);
    }

    pl=strlen(one_sequence);
    n=1;
    one_index=0;

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
      } else {
        a=floor(20*(float)rand()/RAND_MAX);
        MP[a][i]++; 
        measured_aa_freq[a]++;
      } // replace B, X, Z etc. with random amino acid to preserve size distribution
    }
    MP[20][pl]++;
    measured_aa_freq[20]++; // MP[20][n] is the number of sequences of length n in the database 
  }  

  for(i=0;i<MAX_SEQUENCE_LENGTH;i++){
     row_sum[i]=0;
  }
  
  for(i=0;i<MAX_SEQUENCE_LENGTH;i++){ 
    for(j=0;j<=20;j++){ 
      row_sum[i]+=MP[j][i];
    }
  }



  /* generate random protein sequences through Markov chain */


  if ((outp = fopen(outfile, "w"))==NULL) {
    printf("error opening output file %s\n",outfile); 
    return -1;
  }

  for(protein=0;protein<sequences_to_generate;protein++)
  {
      
    i=0; j=0;
    while (1)
    {
      x=(double)row_sum[j]*((double)rand()/RAND_MAX);
      partial_sum=MP[0][j]; i=1;
       
      while (partial_sum<x) {partial_sum+=MP[i][j]; i++;}

      if (j>=MAX_SEQUENCE_LENGTH) { i=21; }/* terminate when sequence has reached MAX_SEQUENCE_LENGTH */
     
      if (i<21)
      {
        random_sequence[j]=AMINO_ACIDS[i-1];j++;generated_aa_freq[i-1]++;
      } else { /* i==21, i.e. protein sequence terminated */ 
        k=0; 
        generated_aa_freq[20]++; 
        generated_pl_sum+=j;
        
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

  
  // printf("done (wrote %li random protein sequences to %s)\n",sequences_to_generate,outfile);

  k=0;l=0;
  for(i=0;i<=20;i++) {k+=measured_aa_freq[i];l+=generated_aa_freq[i];}

  // printf("<average sequence length in %s> = %f\n<average sequence length in %s> = %f\n",infile,measured_pl_sum/(float)n_sequences,outfile,generated_pl_sum/(float)sequences_to_generate);

  return 0;

}


void Init_decoymaker(void) 
{
  VALUE klass = rb_define_class("Decoymaker",rb_cObject);

  rb_define_singleton_method(klass,
    "make_decoys", decoymaker_make_decoys, 4);


}
