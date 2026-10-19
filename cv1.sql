select table_name from tabs;
select table_name from user_tables;
select table_name from all_tables;
select table_name from dba_tables;

desc student;

-- varchar(10) , ked dam ahoj, tak sa to ulozi ako 5 znakov lebo na konci je ukoncovaci znak
--integer == number(38), desatine cisla ako number(5,2)
-- timestamp

--fk - moze byt rekurzivny na sam seba, moze byt aj null ak nepovinnz
--kardinalita 1:n, m:n -> je potrebna nova tabulka, clenstvo vo vztahu -> ci je identifikacny(je sucastou primarneho kluca alebo identifikacny(nie je sucastou pk
/*
viacriadkovy
*/

--ku kazdej osobe studentske udaje
select meno, priezvisko, rod_cislo, os_cislo from student right join os_udaje using(rod_cislo);
--len studenti druheho rocnika
select meno, priezvisko, rod_cislo, os_cislo from student join os_udaje using(rod_cislo) 
    where rocnik = 2;
--osoby ktorych meno zacina na m
select meno, priezvisko, rod_cislo, os_cislo from student join os_udaje using(rod_cislo) 
    where meno like 'M%';

select meno, priezvisko, s.rod_cislo, os_cislo from student s join os_udaje o on (s.rod_cislo = o.rod_cislo) 
    where meno like 'M%';
    
--chcem spajat len v urcitych pripadoch (len pri outer join), v tomto pripade to nema zmysel
select meno, priezvisko, s.rod_cislo, os_cislo from student s join os_udaje o on (s.rod_cislo = o.rod_cislo and meno like 'M%');

--studenti ktory nemali zapisany predmet dat systemy

select meno, priezvisko from os_udaje join student using(rod_cislo)
    where os_cislo not in 
        (select os_cislo from zap_predmety join predmet using(cis_predm) 
            where nazov like 'Data%');

--zoznam studentov ktory mali zapisanych viac ako 5 predmetov
select os_cislo, count(cis_predm) from student left join zap_predmety using (os_cislo) -- count(os_cislo), count(*), count(cis_predm) je to iste
    group by os_cislo
        having count(cis_predm) > 5; --distinct jedinecne
        
--zoznam studentov ktory mali menej ako 5 predmetov

select os_cislo, count(cis_predm) from student left join zap_predmety using (os_cislo) -- count(os_cislo), count(*), count(cis_predm) je to iste
    group by os_cislo
        having count(cis_predm) <= 5; --distinct jedinecne

select os_cislo from student s where not exists (select * from zap_predmety where s.os_cislo=zap_predmety.os_cislo
                                                    group by os_cislo 
                                                    having count(distinct cis_predm) > 5);
                                                    
select sysdate, current_date from dual; -- na serveri sysdate, na lokali current date
alter session set nls_date_format='DD.MM.YYYY HH24:MI:SS';
-- nikdy nepouzivat substring na datum lebo to vyresetuje format tak pouzivat to char

select to_char(sysdate, 'MM') from dual;
select to_char(sysdate, 'Month') from dual;
select add_months(sysdate, -1) from dual;
select trunc(sydate, 'DD') from dual;
select to_char(sysdate, 'Q') from dual; --stvrtrok
select case to_number(to_char(sysdate, 'MM'))
            when 1 then 1
            when 2 then 1 
            when 3 then 1 
            when 4 then 2 
            when 5 then 2 
            when 6 then 2 
            when 7 then 3 
            when 8 then 3
            when 9 then 3
            else 4
            end
            from dual;
            
--ked sa orderuju cisla tak null sa ako max cislo povazuje
select rod_cislo, meno, priezvisko, (listagg(os_cislo, ',') within group (order by rocnik))
    from os_udaje left join student using(rod_cislo)
        group by rod_cislo, meno, priezvisko; 
        
select 'alter table ' || table_name || ' rename to ' || 'st_' || table_name from tabs;

begin
    for i in (select 'alter table ' || table_name || ' rename to ' || 'st_' || table_name as prikaz from tabs)
    loop
        execute immediate i.prikaz;
    end loop;
end;
/

begin
    for i in (select 'alter table ' || table_name || ' rename to ' || 'st_' || subst(table_name, 3) as prikaz from tabs)
    loop
        execute immediate i.prikaz;
    end loop;
end;
/

rollback;


--vypisanie cudzich klucov
select constraint_name, us.table_name as tabulka_s_cudzim_klucom, listagg(column_name, ',') within group (order by position) 
    from user_constraints us join user_cons_columns co using (constraint_name) where constraint_type='R'
        group by constraint_name, us.table_name; 
--vypisanie primarny kluc
select constraint_name, us.table_name, listagg(column_name, ',') within group (order by position) 
    from user_constraints us join user_cons_columns co using (constraint_name) where constraint_type='P'
        group by constraint_name, us.table_name;
        
        
--
select us.constraint_name, us.table_name as tabulka_s_cudzim_klucom, us2.table_name as tabulka_s_primarnym_klucom,
    listagg(co.column_name, ',') within group (order by co.position) as stlpce_cudzieho_kluca, 
    listagg(co2.column_name, ',') within group (order by co2.position) as stlpce_primarneho_kluca
    from user_constraints us join user_cons_columns co on (us.constraint_name = co.constraint_name) 
                             join user_constraints us2 on (us.r_constraint_name = us2.constraint_name)
                             join user_cons_columns co2 on (us2.constraint_name = co2.constraint_name)
        where us.constraint_type='R'
            group by us.constraint_name, us.table_name, us2.table_name;
/
--najprv tabulka s cudzim klucom, potom tabulka s primarnym klucom
select 'alter table ' || tabulka_s_cudzim_klucom || ' drop constraint ' || constraint_name from zaloha_fk_tab;
begin
for i in (select 'alter table ' || tabulka_s_cudzim_klucom || ' drop constraint ' || constraint_name as prikaz from zaloha_fk_tab)
    loop
        execute IMMEDIATE i.prikaz;
    end loop;
end;
/
select 'alter table ' || tabulka_s_cudzim_klucom || ' add foreign key (' || stlpce_cudzieho_kluca  || ') references ' || tabulka_s_prim_klucom
    || '(' || stlpce_primarneho_kluca || ')' from zaloha_fk_tab;
    
--zrusit si aj primarny kluc
--najprv zrusim cudzi kluc, potom drop 
--kurzor ako list agg
select meno, priezvisko, cursor(select os_cislo from student where student.rod_cislo=os_udaje.rod_cislo)
    from os_udaje;
-- vypisat zaznamy spojito
select min(datum) as zaciatok, max(datum) as koniec, aktivita from
    (select rank() over(partition by aktivita order by datum) rnk , aktivita, datum from kvet3.rekonstrukcia)
        group by aktivita, datum-rnk
            order by min(datum);
            
--objekt, specifikacia telo
create or replace type adresa as object(ulica varchar2(20),
                                        psc number(5),
                                        obec varchar2(20),
                                        member function vypis return varchar2
                                        );
                                        /
--defaultne je to file musime pretypovat
create or replace type body adresa as 
    member function vypis return varchar2
    is 
        begin
            return ulica || ', ' || obec || ', ' || psc; 
        end;
end;
/

create table tabulka_obj of adresa;
--cascade 
alter type adresa modify attribute (obec varchar2(50)) cascade;
insert into tabulka_obj 
select adresa(ulica, psc, obec) from os_udaje;
select value(p), ulica, value(p).ulica, value(p)adresa_print from tabulka_obj;


--domaca uloha: vytvorit tabulku objektov osoba, rodcislo, meno, priezviskoa a (adresa trvaleho pobytu a prechodneho pobytu ako objekty) 

select os_cislo from ucitel where os_cislo in (select prednasajuci, count(distinct cis_predm) from zap_predmety having );
select prednasajuci, listagg(distinct cis_predm, ',') from zap_predmety group by prednasajuci having count(distinct cis_predm) <= 2;

select os_cislo from student where os_cislo in (select os_cislo from zap_predmety where vysledok = 'A' group by os_cislo having count(vysledok) = 
    (select (max(count(VYSLEDOK))) from ZAP_PREDMETY
                                       where VYSLEDOK = 'A'
                                            group by OS_CISLO));
select meno, PRIEZVISKO
    from UCITEL
        where not exists(select 'x'
                            from ZAP_PREDMETY);
select meno, priezvisko, os_cislo from ucitel 
    where os_cislo not in (select prednasajuci from zap_predmety);
select prednasajuci from zap_predmety where prednasajuci = 'KDS03';

select PRIEZVISKO
    from UCITEL
        where not exists(select 'x'
                          from STUDENT st join OS_UDAJE os on st.ROD_CISLO = os.ROD_CISLO
                            where os.PRIEZVISKO = UCITEL.PRIEZVISKO);
--pri select into davat pozor na to, ze iba jeden riadok ma byt v selecte vrateny (napriklad problem moze byt ked studuje viac krat)

-- osetrenie vynimky v deklaracii -> musime ju obalit vo funkcii kde oddchytavame vynimku v celom