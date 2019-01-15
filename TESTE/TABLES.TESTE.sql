drop table B;
drop table A;

create table A (
    ID_A1 number not null,
    ID_A2 number not null,
    A1 number,
    primary key(ID_A1,ID_A2)
);

create table B (
    ID_B1 number not null,
    ID_A1 number not null,
    ID_A2 number not null,
    B1 number,
    primary key(ID_B1),
    constraint b_fk1 foreign key (ID_A1,ID_A2) references A(ID_A1,ID_A2)
);