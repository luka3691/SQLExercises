-- vytvorit objektovy typ, meno, priezvisko, rod_cislo, os_cislo, rocnik

create or replace type stud as object
(
    meno varchar2(50),
    priezvisko varchar(100),
    rod_cislo char(11),
    os_cislo number,
    rocnik number
);
/

create or replace type stud_col is table of stud;
/

create table stud_table (
    kolekcia stud_col
) nested table kolekcia store as kolekcia_store
;
/
drop TABLE stud_table;
--insert into stud_table values(1, stud_col(stud('Jozko', 'Mrkva', '11223344556', 1122, 2)));
--insert into stud_table values(2, stud_col(stud('Jozko2', 'Mrkva2', '11223344557', 1123, 1)));
--insert into stud_table values(3, stud_col(stud('Jozko3', 'Mrkva3', '11223344558', 1124, 3)));
declare
    v_kolekcia stud_col;
begin
    select stud(meno, priezvisko, rod_cislo, os_cislo, rocnik) bulk collect into v_kolekcia from student join os_udaje using (rod_cislo)   ;
        insert into stud_table values (v_kolekcia);
end;
/
select * from stud_table; 
declare 
    v_kolekcia stud_col;
begin 

    select kolekcia into v_kolekcia from stud_table;
        
        for i in reverse 1..v_kolekcia.count 
            loop
                if v_kolekcia(i).rocnik = 2
                    then  v_kolekcia.delete(i);
                end if;
            end loop;
            update stud_table set kolekcia = v_kolekcia;
    
end;
/
--ALEBO 
select kol.* from stud_table s, table(s.kolekcia) kol
where rocnik = 1;
select * from stud_table s, table(s.kolekcia) kol where kol.rocnik = 1;

select xmlroot(
    xmlelement("students", 
        xmlagg(xmlelement('student',
        xmlforest(meno as "meno",
                    priezvisko as "priezvsiko",
                    rod_cislo as "rod_cislo",
                    os_cislo as "os_cislo",
                    rocnik as "rocnik")
        )
        )
    )


, version '1.0') as xml from stud;
select json_object(
        'kolekcia' value (
            select json_arrayagg(
            json_object(
                'meno' value s.meno,
                'priezvisko' value s.priezvisko,
                'rod_cislo' value s.rod_cislo,
                'os_cislo' value s.os_cislo,
                'rocnik' value s.rocnik
            )
            ) from table(t.kolekcia) s
        )
) as json_data
    from stud_table t;


--select zozanm osob, pre kazdu kolko predmetov mala a kolko bolo z nich na acko
select meno, priezvisko, count(cis_predm), sum(case when vysledok = 'A' then 1 else 0 end) from os_udaje join student using (rod_cislo) join zap_predmety using (os_cislo)
    group by meno, priezvisko, rod_cislo;