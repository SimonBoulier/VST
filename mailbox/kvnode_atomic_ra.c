#include "gen_atomics.h"

typedef struct node { int *version; int *data[8]; } node;

void read(node *n, int *out){
  while(1){
    int *ver = n->version;
    int snap = load_acq(ver);
    if(snap & 1 == 1) continue; //already dirty
    for(int i = 0; i < 8; i++){
      int *l = n->data[i];
      out[i] = load_acq(l);
    }
    int v = load_acq(ver);
    if(v == snap) return;
  }
}

//We can make this work for multiple writers by enclosing it in a similar loop.
void write(node *n, int *in){
  int *ver = n->version;
  int v = load_acq(ver);
  store_rel(ver, v + 1);
  for(int i = 0; i < 8; i++){
    int *l = n->data[i];
    int d = in[i];
    store_rel(l, d);
  }
  store_rel(ver, v + 2);
}

node *make_node(){
  node *n = surely_malloc(sizeof(node));
  n->version = surely_malloc(sizeof(int));
  n->data = surely_malloc(sizeof(int*) * 8);
}

void *writer(node *n){
  int data[8] = {0, 0, 0, 0, 0, 0, 0, 0};
  for(int i = 0; i < 3; i++){
    for(int j = 0; j < 8; j++){
      data[8]++;
    }
    write(n, data);
  }
  return NULL;
}

void *reader(node *n){
  int data[8];
  read(n, data);
  return NULL;
}