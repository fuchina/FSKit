//
//  FSLeftController.m
//  FSKit_Example
//
//  Created by Fudongdong on 2018/4/20.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSLeftController.h"

struct LinkList {
    int data;
    struct LinkList *next;
};

typedef struct LinkList LinkList_Single;

@interface FSLeftController ()

@end

@implementation FSLeftController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"Click" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[btn]-15-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(btn)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-100-[btn(44)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(btn)]];
}

LinkList_Single* makeALinkListUnit(){
    LinkList_Single *unit = (LinkList_Single *)malloc(sizeof(LinkList_Single));
    memset(unit, 0, sizeof(LinkList_Single));
    return unit;
}

- (LinkList_Single *)aLinkList_Single{
    LinkList_Single *head = makeALinkListUnit();
    if (head == NULL) {
        return NULL;
    }
    int number = 0;
    head->data = 0;
    LinkList_Single *temp = head;
    while (number < 20) {
        LinkList_Single *u = makeALinkListUnit();
        if (u) {
            u->data = number + 1;
            temp->next = u;
            temp = u;
            number ++;
        }else{
            return NULL;
        }
    }
    return head;
}

void printLinkList(LinkList_Single *list){
    LinkList_Single *temp = list;
    while (temp) {
        NSLog(@"v:%@",@(temp->data));
        temp = temp->next;
    }
    NSLog(@"\n\n\n\n");
}

- (void)click{
    LinkList_Single *list = [self aLinkList_Single];
    printLinkList(list);
    LinkList_Single *red = reverseLinkList(list);
    printLinkList(red);
}

// 链表反转
LinkList_Single* reverseLinkList(LinkList_Single *head){
    LinkList_Single *p,*q,*pr;
    p = head->next;
    q = NULL;
    head->next = NULL;
    while(p){
        pr = p->next;
        p->next = q;
        q = p;
        p = pr;
    }
    head->next = q;
    return head;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
