
select table_name from dba_tables where owner='SOC_POISTOVNA';
 
grant select on XXXX to PUBLIC with grant option;
 
select 'grant select on soc_poistovna.'|| table_name ||' to public;' 
from dba_tables where owner='SOC_POISTOVNA';

-- vytvorit objektovy typ poberatel

create or replace type t_poberatel is object(
    id_poberatela number,
    rod_cislo char(11),
    id_typu number,
    
    member function daj_typ return varchar2
);

create or replace type body t_poberatel
as
    member function daj_typ return varchar2
    is
        v_popis varchar2(50);
    begin
        select popis into v_popis from soc_poistovna.p_typ_prispevku
            where id_typu = self.id_typu;
        return v_popis;
    end;
end;
/


--vytvorit typ kolekciu

create or replace type poberatelia is varray(10) of t_poberatel;
/
--create or eplace sa neda pre tabulku
create table poberatelia_test (
    rod_cislo varchar2(50),
    meno varchar2(50),
    priezvisko varchar2(50),
    poberatelia_col poberatelia
);
/
declare
    cursor osoba
    is 
    select distinct rod_cislo, meno, priezvisko 
    from soc_poistovna.p_osoba
    join soc_poistovna.p_poberatel using (rod_cislo)
    where rownum <= 10;

    v_kolekcia poberatelia;
    v_rod_cislo varchar2(50);
    v_meno varchar2(50);
    v_priezvisko varchar2(50);
begin
    open osoba;

    for i in 1 .. 10
    loop
        fetch osoba into v_rod_cislo, v_meno, v_priezvisko;
        select t_poberatel(id_poberatela, rod_cislo, id_typu)
        bulk collect into v_kolekcia
        from soc_poistovna.p_poberatel
        where rod_cislo = v_rod_cislo;

        insert into poberatelia_test
        values (v_rod_cislo, v_meno, v_priezvisko, v_kolekcia);
    end loop;

    close osoba;
end;
/

select * from poberatelia_test;
--mame objektovy typ a chcem ziskat instanciu tak zavolam konstruktor
select original.rod_cislo, meno, priezvisko, t_poberatel(relacna_kolekcia.id_poberatela, relacna_kolekcia.rod_cislo, relacna_kolekcia.id_typu).daj_typ
    from poberatelia_test original,
    table(select pob.poberatelia_col from poberatelia_test pob
        where original.rod_cislo = pob.rod_cislo) relacna_kolekcia;
    
select id_typu, popis 
from soc_poistovna.p_typ_prispevku;
select rod_cislo, count(*) as celkom
from soc_poistovna.p_poberatel
group by rod_cislo;
select rod_cislo, case when id_typu = 1 then 1
                       else 0 
                   end
  from soc_poistovna.p_poberatel;     
select rod_cislo, sum(case when id_typu = 1 then 1
                       else 0 
                   end) as pocet_ztp, 
                  sum(case when id_typu = 2 then 1
                       else 0 
                   end) as pocet_prispevkov_na_dieta, 
                   count(case when id_typu = 3 then 1
                       else null 
                   end) as pocet_nezam 
  from soc_poistovna.p_poberatel
    group by rod_cislo;      
--riadky - studijne odbory
--stlpce - pocet studentov v rocnikoch
--pre kazdy rocnik jeden case

select rod_cislo, meno, priezvsiko, json_objectagg(
        'poberatel' value id_poberatela,
        'rod_cislo' value rod_cislo,
        'id_typu' value id_typu
) from soc_poistovna.p_poberatel p
    join soc_poistovna.p_osoba using (rod_cislo)
        ;
--odchylka
--123456
--987654
--5555
--odchylka 0,08