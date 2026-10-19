--zoznam studentov ktory mali zapisanych viac ako 5 predmetov
select meno, priezvisko, rod_cislo, count(*) from student join os_udaje using (rod_cislo) join zap_predmety using (os_cislo)
     having count(*) > 5 group by meno, priezvisko, rod_cislo;
     
create or replace type adresa as object(ulica varchar2(20),
                                        psc number(5),
                                        obec varchar2(20),
                                        member function vypis return varchar2
                                        );
                                        /
create or replace type body adresa as
    member function vypis return varchar2
    is
     begin
            return ulica || ', ' || obec || ', ' || psc; 
     end;
     
end;
/
insert into tabulka_obj 
select adresa(ulica, psc, obec) from os_udaje;
update os_udaje set psc = 97405 where psc = '065 0';
select value(p), ulica, value(p).ulica from tabulka_obj p;

-- ku kaûdej osobe vyp˝saù koæko m· predmetov
select meno, priezvisko, rod_cislo, count(distinct cis_predm) from student join os_udaje using (rod_cislo) left join zap_predmety using (os_cislo)
    group by meno, priezvisko, rod_cislo;

-- osoba ktor· m· najviac predmetov
--vybrat s maximom
select meno, priezvisko, rod_cislo, count(distinct cis_predm) from student join os_udaje using (rod_cislo) left join zap_predmety using (os_cislo)
    group by meno, priezvisko, rod_cislo order by count(distinct cis_predm) desc 
    fetch first 1 rows only;

with dotaz as (select meno, priezvisko, rod_cislo, count(distinct cis_predm) as pocet from student join os_udaje using (rod_cislo) left join zap_predmety using (os_cislo)
    group by meno, priezvisko, rod_cislo order by count(distinct cis_predm) desc)
    select * from (select meno, priezvisko, rod_cislo, pocet, dense_rank() over (order by pocet desc) rn from dotaz) dotazik
    where rn = 1;

with dotaz as (select meno, priezvisko, rod_cislo, count(distinct cis_predm) as pocet from student join os_udaje using (rod_cislo) left join zap_predmety using (os_cislo)
    group by meno, priezvisko, rod_cislo order by count(distinct cis_predm) desc)
    select * from dotaz 
    where pocet = (select max(pocet) from dotaz);

--VypÌöte predmety, ktorÈ vûdy garantoval ten ist˝ Ëlovek (atrib˙t garant v tabuæke predmet_bod). 

select meno, priezvisko, os_cislo, listagg( distinct cis_predm, ',') from ucitel join predmet_bod on(ucitel.os_cislo = predmet_bod.garant)
    group by meno, priezvisko, os_cislo;
    
--VypÌöte uËiteæov, ktori uËili najviac 2 rÙzne predmety (atrib˙t prednasajuci v tabuæke zap_predmety).
select meno, priezvisko, prednasajuci, count( distinct cis_predm) from ucitel join zap_predmety on (ucitel.os_cislo = zap_predmety.prednasajuci)
    group by meno, priezvisko, prednasajuci
        having count( distinct cis_predm) <= 2;

--VypÌöte ötudentov, ktorÌ iöli vûdy na sk˙úku po viac ako 3 dÚoch od z·poËtu
select os_cislo from student where exists (select 'X' from zap_predmety
    where zapocet is not null and datum_sk is not null and (zapocet - datum_sk) >= 3);

--VypÌöte ötudenta, ktor˝ m· najviac ¡Ëok zo sk˙öok. 
with pocetA as (
select os_cislo, count(vysledok) as pocet from zap_predmety 
        where vysledok = 'A' group by os_cislo)
select os_cislo from student where os_cislo in (
select os_cislo from pocetA where pocet = 
(select max(pocet) from 
    (pocetA)));
    
--Pre kaûd˝ odbor vypÌöte roËnÌk, v ktorom je najviac ötudentov. 
with stat as (select st_odbor, rocnik, count(*) as pocet from student 
    where ukoncenie is null group by st_odbor, rocnik)
select st_odbor, rocnik, pocet from stat s1 
    where pocet = (select max(pocet) from stat s2 
        where s1.st_odbor = s2.st_odbor)
;

--VypÌöte zoznam uËiteæov, ktorÌ predn·öali rovnak˝ predmet aspoÚ 3 roky po sebe
with zoznam as (select prednasajuci, cis_predm , skrok 
    from zap_predmety group by prednasajuci, skrok, cis_predm
    order by prednasajuci, skrok, cis_predm),
ajpredch as (select prednasajuci, cis_predm, skrok,
    lag(skrok, 1) over (partition by prednasajuci, cis_predm order by skrok)
        as predcha from zoznam),
sekvencie as (select prednasajuci, cis_predm, 
    sum(case when skrok - nvl(predcha, skrok) > 1 then 0 else 1 end) as dlzkaSerie
    from ajpredch group by prednasajuci, cis_predm)
select prednasajuci, cis_predm from sekvencie where dlzkaserie >= 3;
--. VypÌöte vöetky osoby, k nim inform·cie o öt˙diu

--Pre kaûd˝ odbor vypÌöte poËet ötudentov v jednotliv˝ch roËnÌkoch ako tabuæku:
select rocnik,
 sum(case when substr(rod_cislo,3,1)>4 then 1 else 0 end) as pocet_zien,
 sum(case when substr(rod_cislo,3,1)<2 then 1 else 0 end) as pocet_muzov
from student
 group by rocnik
 order by rocnik;
 
--VypÌöte zoznam vöetk˝ch predmetov. Ak je to predmet, ktor˝ m· v n·zve slovo ìdataî, tak vypÌöte aj poËet zapÌsan˝ch ötudentov (potlaËte duplicity), inak NULL. 
select cis_predm, nazov, 
    (case when nazov like '%data%' then 
        (select count(distinct os_cislo) from zap_predmety z1 where p1.cis_predm = z1.cis_predm) 
        else null end) as pocet 
from predmet p1;

-- Vygenerujte prÌkaz na rebuildovanie vöetk˝ch indexov ñ Alter index index_name rebuild;
select 'alter index ' || index_name || ' rebuild;' as statementik from user_indexes;
--Vygenerujte prÌkaz na rekompil·ciu proced˙r a funkciÌ 
select 'alter ' || object_type || ' ' || object_name || 'compile;'  from user_procedures where object_type = upper('function') or object_type = upper('procedure');

declare
    cursor cursorik is (select 'alter index ' || index_name || ' rebuild;' as statementik from user_indexes);
    retazec varchar2(500);
begin
    open cursorik;
    loop
        fetch cursorik into retazec;
        if cursorik%NOTFOUND then exit;
        end if;
        dbms_output.put_line(retazec);
            --execute immediate retazec;
    end loop;
    close cursorik;
end;
/

--Vytvorte proced˙ru, ktor· v kurzore spracuje a vypÌöe osoby narodenÈ v danom mesiaci (mesiac bude parametrom funkcie).
create or replace procedure dajOsoby(mesiac number)
as
    cursor cursorik is (select rod_cislo, meno, priezvisko from os_udaje);
    v_rod_cislo os_udaje.rod_cislo%TYPE;
    v_meno os_udaje.meno%TYPE;
    v_priezvisko os_udaje.rod_cislo%TYPE;
    v_mesiac number;
begin
    v_mesiac := mesiac;
    open cursorik;
    loop
        fetch cursorik into v_rod_cislo, v_meno, v_priezvisko;
        --if cursorik%NOTFOUND then exit;
        --end if;
        exit when cursorik%NOTFOUND;
        if mod(substr(v_rod_cislo, 3, 2), 50) = mesiac then 
        dbms_output.put_line(v_meno || ' ' || v_priezvisko);
        end if;
        
    end loop;
    close cursorik;
end;
/

exec dajOsoby(12);

--Vytvorte funkciu, ktor· vr·ti rodnÈ ËÌslo najstaröej osoby. Ak je ich viac s rovnak˝m vekom,
--potom ich vr·ùte ako reùazec viacer˝ch rodn˝ch ËÌsel oddelen˝ch medzerou.

--Ku kaûdej ötudÌjnej skupine vypÌöte 2 ötudentov, ktorÌ sa zapÌsali v minulosti 
with opakovac as ((select rod_cislo from student st2 group by rod_cislo having count(*) = 2))
select st_skupina, rod_cislo from student st1
    where rod_cislo in (select rod_cislo from student st2 
        where st1.st_skupina=st2.st_skupina and st1.rod_cislo = st2.rod_cislo 
            and rod_cislo in (select rod_cislo from opakovac) fetch first 2 rows only);
-- Ku kaûdÈmu odboru vypÌöte 10 najlepöÌch ötudentov podæa v·ûenÈho ötudijnÈho priemeru. 
with priemerik as (select os_cislo, sum(case vysledok when 'A' then 1
                        when 'B' then 1.5 
                        when 'C' then 2 
                        when 'D' then 2.5
                        when 'R' then 3
                        else 5 end) / count (*) as priemer from zap_predmety where vysledok is not null group by os_cislo
)
select * from (select st_skupina, os_cislo, priemer, rank() over (partition by st_skupina order by priemer desc) as poradie from student join priemerik using (os_cislo))
where poradie < 10;

with priemerik as (select os_cislo, sum(case vysledok when 'A' then 1
                        when 'B' then 1.5 
                        when 'C' then 2 
                        when 'D' then 2.5
                        when 'R' then 3
                        else 5 end) / count (*) as priemer from zap_predmety where vysledok is not null group by os_cislo
)
select * from (select st_skupina, os_cislo, priemer, rank() over (partition by st_skupina order by priemer desc) as poradie from student join priemerik using (os_cislo)) stk
where poradie <= (select count(*)*0.1 + 1 from student stk2 where stk.st_skupina = stk2.st_skupina);
                        
create type os_cisielka is table of number;
/
create table tabulka1  
( rod_cislo char(11) primary key,
    os_cisla os_cisielka
) nested table os_cisla store as os_cisielka_stor;
/
select rod_cislo from os_udaje;
select * from os_udaje, table(select os_cislo from student where os_udaje.rod_cislo = student.rod_cislo) nested;
create or replace procedure insertik
as
    v_rod_cislo student.rod_cislo%TYPE;
    v_os_cisla os_cisielka;
    cursor kurzorik1 is (select distinct rod_cislo from student);
    cursor kurzorik2 is (select os_cislo from student where rod_cislo = v_rod_cislo);
begin
    open kurzorik1;
    loop
        fetch kurzorik1 into v_rod_cislo;
            open kurzorik2;
                loop
                v_os_cisla 
                end loop;
            close kurzorik2;
        
        
    end loop;
    close kurzorik1;
end;
/
INSERT INTO tabulka1 (rod_cislo, os_cisla)
SELECT rod_cislo, CAST(COLLECT(os_cislo) AS os_cisielka)
FROM student
GROUP BY rod_cislo;
/

--Z tabuæky vytvorenej v predch·dzaj˙cej ˙lohy vymaûte vöetky osobnÈ ËÌsla, ak uû ötudent ukonËil öt˙dium. 
UPDATE tabulka1
SET os_cisla = NULL
WHERE rod_cislo IN (SELECT rod_cislo FROM student where ukoncenie is not null);
/

--Vytvorte objektov˝ typ, ktor˝ bude obsahovaù ËÌslo predmetu a n·zov. DoplÚte metÛdu na triedenie podæa poËtu zapÌsan˝ch ötudentov na dan˝ predmet. 
create or replace type predmetik as object
(cislo varchar2(10), 
nazov varchar2(50),
map member function tried return number
    );
    /
CREATE TABLE predmety (
    predmet predmetik, -- Typ pre ËÌslo predmetu a n·zov
    pocet_studentov NUMBER -- PoËet zapÌsan˝ch ötudentov
);
/

 
 select xmlroot( xmlelement("predmet", xmlattributes(cis_predm as "cislo", nazov as "nazov"),
            xmlagg(xmlelement("student", xmlattributes(os_cislo as "osobne")))
 
 ) ,version 1.0) xml from zap_predmety join predmet using (cis_predm) group by cis_predm, nazov;
 
 drop type t_kniha force;
 create type t_kniha as object
(
    nazov varchar2(30),
    zaner varchar2(30),
    vydavatelstvo varchar2(30),
    rok_vydania integer,
    map member function tried return number
);
/


alter type t_kniha
    add member function vypis return varchar;
/
alter type t_kniha
    add map member function tried return number;
/
alter type t_kniha modify attribute(nazov varchar2(50) cascade);
create or replace type body t_kniha
is
map member function tried return number 
is
begin
    if (self.rok_vydania > 2010) then return 1; 
        else return 2;
    end if;
end;
member function vypis return varchar 
is
begin
    return 'Meno:' || self.nazov || '. é·ner:' || self.zaner; 
end;

end;
/
create table kniha_tab of t_kniha;

desc kniha_tab;

alter table kniha_tab
    add constraint kniha_tab_pk primary key (NAZOV);
    
insert into kniha_tab (nazov, zaner, vydavatelstvo, rok_vydania) (select rod_cislo, meno, substr(obec, 1, 29), psc from os_udaje);

select zaner from kniha_tab;
select value(s).vypis() from kniha_tab s order by value(s);

alter type t_kniha add map member function tried return integer cascade ; -- keÔûe s˙ uû nejakÈ objekty na tomto type z·vislÈ, npreto to musÌme pomocou cascade upraviù vöade
/
alter type t_kniha drop map member function tried return integer cascade ;
create or replace type t_kniha body
as
    member function vypis return varchar 
is
begin
    return 'Meno:' || self.nazov || '. é·ner:' || self.zaner; 
end;
map member function tried return integer
    is
        poradie integer;
    begin
        select case 
            when substr(zaner, 3, 2)>50 then 1
            else 2 end into poradie from DUAL;
        return poradie || ascii(nazov); -- ak s˙ obe rovnakÈ tak potom podla asi kÛdu
    end;
end;
 /
 
 create type t_ebook under t_kniha
(
    format char(4)
);
/
-- po tomto to zbehne
alter type t_kniha not final cascade;

alter type t_ebook
    add overriding member function vypis return varchar;
/

create or replace type body t_ebook
is
    overriding member function vypis return varchar
    is
    begin
        -- rpad pouûijeme na krajöÌ vypÌs prvÈ je Ëo sa ma vypÌsaù a drh˝ parameter je koæko znakov sa ma vypÌsaù (pripadne aj white znakov)
        return (SELF as t_kniha). VYPIS() || format;
    end;
end;
/
create table kniha_tab2 of t_kniha;
insert into kniha_tab2 select value(k) from kniha_tab k;
insert into kniha_tab values (t_ebook('Harry Potter', 'fantasy', 'edis', 2023, 'PDF'));
select value(k).vypis() from kniha_tab2 k
    order by value(k);
select k.*, treat(value(k) as t_ebook).FORMAT from kniha_tab2 k
    order by value(k);

select k.*, treat(value(k) as t_ebook).FORMAT from kniha_tab2 k
    where value(k) is of (only T_KNIHA)
        order by value(k);

 -- VypÌöte 5% obyvateæov s najlepöimy znamkami pre kaûdÈ program. (3 b):
 with priemerik as (select os_cislo, sum(case vysledok when 'A' then 1 when 'B' then 2 when 'C' then 3 when 'D' then 4 when 'E' then 5 else 6 end) / count(*) as priemer from zap_predmety group by os_cislo),
pozicia as (select os_cislo, priemer, st_odbor, rank() over (partition by st_odbor order by priemer asc) as pozicica from student join priemerik using (os_cislo))
 select st_odbor, os_cislo from pozicia koko
 where pozicica <= (select count(*) * 0.05 + 1 from student st where koko.st_odbor = st.st_odbor);
 ;
 -- vytvorte tabuæku ktor· bude maù 2 atrib˙ty, rodnÈ Ëislo a xml dokument
 create table xmlko (rod_cislo char(11), dokument xmltype);
 -- v xml budeme maù roËnÌk a zaËiatok a koniec öt˙dia vyrobÌme element ktor˝ sa vol· ˙daj
 select xmlroot(xmlelement("udaj",xmlelement("rocnik", rocnik), xmlelement("zaËiatok", dat_zapisu), xmlelement("konie", ukoncenie)), version 1.0)xml from student;
  select xmlroot(xmlelement("student",xmlagg(  xmlelement("udaj",xmlattributes(os_cislo as "osobne_cislo"),xmlelement("rocnik", rocnik), xmlelement("zaËiatok", dat_zapisu), xmlelement("konie", ukoncenie)))), version 1.0)xml from student;
  /
 -- vloûÌm tento select do tabulky a je tam a vyberieme rodnÈ ËÌslo a xml dokument
 insert into xmlko (select rod_cislo,
    xmlroot(xmlelement("student",xmlagg(  xmlelement("udaj",xmlattributes(os_cislo as "osobne_cislo"),xmlelement("rocnik", rocnik), xmlelement("zaËiatok", dat_zapisu), xmlelement("konie", ukoncenie)))), version 1.0) 
    from student group by rod_cislo);

select * from xmlko;
-- vyp˝saù vöetky roËnÌky z tabuæky tablex
select extract(s.dokument, '/student/udaj/rocnik') from xmlko s;
SELECT DISTINCT rocnik
FROM xmlko, XMLTABLE('/student/udaj' PASSING dokument COLUMNS rocnik VARCHAR2(50) PATH 'rocnik');
SELECT DISTINCT 
    EXTRACTVALUE(VALUE(d), '/udaj/rocnik') AS rocnik
FROM xmlko x, TABLE(XMLSEQUENCE(EXTRACT(x.dokument, '/student/udaj'))) d;
/

select extractvalue(value(d),'/udaj/@osobne_cislo') from xmlko s, table(xmlsequence(extract(s.dokument, '/student/udaj'))) d where rod_cislo = '791229/5431';
/
update xmlko s set s.dokument = updateXML(
        s.dokument ,
        '/student/udaj[@osobne_cislo="501333"]/@osobne_cislo',
        '999999'
    ) where rod_cislo = '791229/5431'; /
-- Vytvorte si kolekciu ako typ, ktor˙ koævek chceme

create or replace type o_osoba as object
(
    meno varchar2(20),
    priezvisko varchar2(20),

    map member function tried return integer
);
/

create or replace type body o_osoba as
    map member function tried return integer is
    begin
        return length(PRIEZVISKO);
    end;
end;
/

create or replace type nested_table is table of o_osoba;
/
create table osoba_table 
(rocnik integer, collection nested_table)
nested table collection store as coll;
-- objekt ktor˝ bude volaù meno a priezvisko, (konötruktor) a potom z t˝ch jednotliv˝ch z·znaomov spravim kolekciu
select cast(collect(o_osoba(n.meno, n.priezvisko))as nested_table)
from os_udaje n;
-- m·m kolelkciu, teraz chcem pre kaûd˝ roËnÌk vytvoriù kolekciu, COLLECT je agregaËn· funkcia, takûe pouûijem GROUP BY
insert into osoba_table (select rocnik, cast(collect(o_osoba(n.meno, n.priezvisko))as nested_table) from os_udaje n join student s using (rod_cislo) group by rocnik);
-- aktualizujeme krstnÈ men· tak aby sa vöetci prv·ci volali michal
select * from table(select collection from osoba_table where rocnik = 1);
update table (select collection from osoba_table where rocnik = 1) set meno = 'Michal';

create table obor_xml_ty of xmltype;

insert into obor_xml_ty (select xmlroot(
            xmlelement("osoba",
                xmlelement(
                "meno", meno
                ),
            xmlelement(
                "priezvisko", priezvisko
                ),
            xmlelement("studium",
                XMLAGG(
                    xmlelement(
                    "odbor",
                    xmlattributes (os_cislo as "os_cislo"),
                    st_odbor
                    )
                )
                )
            )
           , version '1.0')
    from OS_UDAJE join STUDENT using (rod_cislo)
        group by MENO, PRIEZVISKO, rod_cislo);

SELECT DISTINCT EXTRACTVALUE(VALUE(x), '/odbor/@os_cislo') AS os_cislo
FROM obor_xml_ty t,
     TABLE(XMLSEQUENCE(EXTRACT(t.object_value, '/osoba/studium/odbor'))) x;
--json
     
create table json_table_dva (
    data clob check (data is json)
)
/

 insert into json_table_dva select
    JSON_OBJECT(
        'meno' value meno,
        'priezvisko' value PRIEZVISKO,
        'studium' value json_arrayagg(json_object(
            'oc' value os_cislo,
            'odbor' value st_odbor
            ))
        )
        from OS_UDAJE join student using(rod_cislo)
            group by meno, PRIEZVISKO, rod_cislo;
    --pre kazdy rok osobitne vypisat pocet novych poberatelov zien a muzov osobitne ()
 select dva.data.meno, dva.data.priezvisko, bb.odbor from json_table_dva dva, json_table(dva.data.studium, '$' columns(odbor varchar2(50) path '$.odbor')) bb order by dva.data.meno;
 
 select extractvalue(value (t), 'osoba/meno') as meno,
       extractvalue(value (t), 'osoba/priezvisko') as priezvisko,
       extractvalue(odbor_table.column_value, 'odbor') as odbor,
       extractvalue(odbor_table.column_value, 'odbor/@os_cislo') as os_cislo
    from obor_xml_ty t, table(XMLSEQUENCE(extract(value(t), 'osoba/studium/odbor'))) odbor_table;
    
select json_object('meno' value meno, 'priezvisko' value priezvisko, 'studium' value json_arrayagg(json_object('oc' value os_cislo, 'odbor' value odbor))) from (
 select extractvalue(value (t), 'osoba/meno') as meno,
       extractvalue(value (t), 'osoba/priezvisko') as priezvisko,
       extractvalue(odbor_table.column_value, 'odbor') as odbor,
       extractvalue(odbor_table.column_value, 'odbor/@os_cislo') as os_cislo
    from obor_xml_ty t, table(XMLSEQUENCE(extract(value(t), 'osoba/studium/odbor'))) odbor_table
) group by meno, priezvisko;

create table json_tab (
    data clob check (data is json)
)
/

insert into json_tab (
    select
        JSON_OBJECT(
            'meno' value meno,
            'priezvisko' value priezvisko,
            'studium' value json_arrayagg(json_object(
                'oc' value os_cislo,
                'odbor' value st_odbor
                ))
            )
            from (
                select extractvalue(value (t), 'osoba/meno') as meno,
                        extractvalue(value (t), 'osoba/priezvisko') as priezvisko,
                        extractvalue(odbor_table.column_value, 'odbor') as st_odbor,
                        extractvalue(odbor_table.column_value, 'odbor/@os_cislo') as os_cislo

                    from obor_xml_ty t, table(XMLSEQUENCE(extract(value(t), 'osoba/studium/odbor'))) odbor_table
                 )
            group by meno, priezvisko
        );
        /
-- mam json tabulku chcem vytvoriù xml tabulku
    -- z pola urobim relacnu tabulku pomocou funkcie json_table
    
select json_value(b.data, '$.meno') as meno,json_value(b.data, '$.priezvisko') as priezvisko, oc, odbor  
    from json_tab b, json_table(b.data, '$.studium[*]' columns (oc varchar2(50) path '$.oc', odbor varchar2(50) path '$.odbor'))jt;

update json_tab jt set jt.data = json_mergepatch(jt.data, '{"studium" : [{ "odbor" : "3000"}]}' ) where json_value(jt.data,  '$.studium[*].odbor') = '200';
select * from json_tab jt;
create table moja_zaloha (id integer);
rollback;
create or replace procedure vloz (id integer)
is
begin
    insert into moja_zaloha values (id);
end;
/


begin
    for i in 1.. 5
        loop
            insert into moja_zaloha values(i);
            vloz(-i);
        end loop;
end;
/
-- 10 z·znamov
delete from moja_zaloha;

begin
    for i in 1.. 5
        loop
            insert into moja_zaloha values(i);
            rollback;
            vloz(-i);
            commit;
        end loop;
end;
/
-- 5 z·znamov
/
begin
    for i in 1.. 5
        loop
            insert into moja_zaloha values(i);
            rollback;
        end loop;
end;
/

-- vyp˝öe 0


-- autonomn· transakcia, ûije si vojÌm ûivotom

create or replace procedure vloz (id integer)
is
    pragma autonomous_transaction; -- na konci tejto proceduri sa musÌ transakcia ukonËiù komitom alebo rollbackom, preto je rollbacknut·
    -- jednoducho povedanÈ, vûdy ju musÌm na konci ukonËiù
begin
    insert into moja_zaloha values (id);
    rollback;
end;
/

begin
    for i in 1.. 5
        loop
            insert into moja_zaloha values(i);
            vloz(-i);
            
            --rollback;
            commit;
        end loop;
end;
/

commit;
select * from moja_zaloha;
delete from moja_zaloha;
drop table moja_zaloha;
drop procedure vloz;


 --rozdelit rovnomerne do 10 skupin
 -- tabuæka ötudent a chcem ich rozdeliù po 10 na jednotivÈ termÌny, (1.10 na jendom termÌne, 2 10 na druhom termÌne ...)
-- Ëiûe rozdelenie mnoûiny po 10

select meno, priezvisko, rod_cislo, row_number() over (order by rod_cislo) as poradie
    from STUDENT join OS_UDAJE using (rod_cislo);


-- zoberiem poradie, vydelÌm max poËtom v skupine a potom to ceil (ktor· to zaork˙hli do hora
select meno, priezvisko, rod_cislo, ceil(poradie/10) as termin --toto sa rozhodne objavÌ na teste
    from (
        select meno, priezvisko, rod_cislo, row_number() over (order by rod_cislo) as poradie
            from STUDENT join OS_UDAJE using (rod_cislo)
         );

-- sk˙sime to upraviù tak aby bol rozdiel medzi skupinami max 1
select meno, priezvisko, rod_cislo, ceil(poradie/((select count(*) from STUDENT)/4)) as termin --toto sa rozhodne objavÌ na teste
    from (
        select meno, priezvisko, rod_cislo, row_number() over (order by rod_cislo) as poradie
            from STUDENT join OS_UDAJE using (rod_cislo)
         );
 -- pre kazdy den vo februari vypisat kolko ludi sa stalo ztp (aj pre prestupny)
with vsetky as (SELECT LEVEL AS num FROM DUAL CONNECT BY LEVEL <= 29), 
datumy_osobne as (select os_cislo, to_char(dat_zapisu, 'DD') as num from student),
pocet as (select num, count(*) as pocetik from datumy_osobne group by num)
select num, (case when pocetik >= 1 then pocetik else 0 end) 
from vsetky left join pocet using (num)  order by num;


select os_cislo, ceil(poradie/10) as termin from
(select os_cislo, row_number() over (order by rocnik) as poradie from student) ;

 
 --db link
 
 -- Analytika
-- vyp˝saù 10% naj˙speönejöich ötudentov, (maju najviac A-Ëok)
with pocetA as (select os_cislo, sum(case vysledok when 'A' then 1 else 0 end) as pocet from zap_predmety group by os_cislo)
select os_cislo, pocet, poradie from (select os_cislo, pocet, row_number() over (order by pocet desc) as poradie from pocetA)
where poradie <= (select ceil(count(*)*0.1) from student);
-- vyp˝saù 10% naj˙speönejöich ötudentov pre kaûdy odbor, (maju najviac A-Ëok)
with pocetA as (select os_cislo, sum(case vysledok when 'A' then 1 else 0 end) as pocet from zap_predmety group by os_cislo),
pocetB as (select st_odbor, os_cislo, row_number() over (partition by st_odbor order by pocet desc) as poradie from pocetA join student using (os_cislo))
select * from pocetB
where poradie <= (select ceil(count(*)*0.1) from student where pocetB.st_odbor = student.st_odbor);
--najuspesnejsich predmetov
with pocetA as (select cis_predm, sum(case vysledok when 'A' then 1 else 0 end) as pocet from zap_predmety group by cis_predm)
select cis_predm, pocet, poradie from (select cis_predm, pocet, row_number() over (order by pocet desc) as poradie from pocetA)
where poradie <= (select ceil(count(*)*0.1) from predmet);
-- ku kaûdÈmu odboru vyp˝saù 3 najobl˙benejöie predmety (najviac zapisovanÈ predmety)
with pocet as (select cis_predm, st_odbor, count(*) as pocet from zap_predmety join student using (os_cislo) group by cis_predm, st_odbor)
select * from (select st_odbor, cis_predm, row_number() over (partition by st_odbor order by pocet desc) as poradie from (select st_odbor, cis_predm from st_program group by st_odbor, cis_predm) left join pocet using (cis_predm, st_odbor))
where poradie <=3;
;
-- vytvorit datum narodenia z rodneho cisla
-- vyvoriù objekty typu osoba
-- vytvoriù tabuæku osÙb (osoba bude objektov˝ atrib˙t) a do tejto tabuæky vloûiù muûov a ûeny z tabuæky os_udaje, priËom muû a ûena bud˙ podtyp osoby
-- potriediù ich naprÌklad podæa d·tumu narodenia
create or replace type osobicka is object
(
    meno varchar2(50),
    priezvisko varchar2(50),
    rod_cislo varchar2(11)
) not final;
/
create or replace type muz under osobicka(
pohlavie char(1)
);
/
create table osoba_tab
(
    rod_cislo varchar2(11) primary key,
    osoba     osobicka
);
/
drop table osoba_tab2;
drop type muz;
create table osoba_tab2 of osobicka;
create table osoba_tab3 of muz;
insert into osoba_tab2
select muz(meno, PRIEZVISKO, rod_cislo, 'm')
from OS_UDAJE;

create or replace function vypocitajvek(osoba osobicka) return date
is
declare
    den char,
    mesiac char,
    rok char
begin
    den := substr(osoba.rod_cislo, 1, 2);
    mesiac := mod(to_number(substr(osoba.rod_cislo, 3, 2)), 50)
    rok := substr(osoba.rod_cislo, 5, 2);
    dbms_output.put_line(rok);
end
;
/
 --json citanie
create table json_table(
    id integer,
    json_obj clob check (json_obj is json)
);
/
-- vytvoriù tabuæku s id typu integer a JSON atrib˙tom obsahuj˙cim meno, priezvisko,
-- rodnÈ ËÌslo ötudenta a ako pole obsahovaù vöetky dokonËenÈ sk˙öky ktorÈ bude obsahovaù n·zov a zn·mku danÈho predmetu .

insert into json_table
select ROWNUM, jsonObj
from
(select json_object('meno' value meno, 'priezvisko' value priezvisko, 'rod_cislo' value rod_cislo,
        'skusky' value json_arrayagg(json_object('nazov' value cis_predm, 'vysledok' value vysledok))) as jsonObj
from student join os_udaje using (rod_cislo) join zap_predmety using (os_cislo) where vysledok is not null 
group by meno, priezvisko, rod_cislo);

select t.json_obj.meno,t.json_obj.priezvisko, predmet, vysledok from json_table t,
json_table(t.json_obj,'$.skusky[*]' columns (predmet varchar2(50) path '$.nazov',
vysledok varchar2(50) path '$.vysledok'))m;

select json_value(t.json_obj.data, '$.meno') from json_table t, json_table(t.json_obj.data, );
--4. VypÌsaù ötatistiku - riadky kraje, stÂpce prvÈ tri mesiace roku 2018 a pre kaûd˝ kraj koæko bolo dokopy prÌspevkov
with kraje as (select id_kraja, n_kraja, psc from p_kraj join p_okres using(id_kraja) join p_mesto using (id_okresu)),
prispevky as (select rod_cislo, psc, id_poberatela, suma, obdobie from p_osoba p_prispevky join p_poberatel using(id_poberatela) join p_osoba using (rod_cislo) where to_char(obdobie, 'YYYY') = '2018')
select n_kraja, sum(case when to_char(obdobie, 'MM') = '01' then suma else 0 end),
sum(case when to_char(obdobie, 'MM') = '02' then suma else 0 end),
sum(case when to_char(obdobie, 'MM') = '03' then suma else 0 end) from n_kraja left join prispevky using (psc) group by n_kraja

/
select months_between(sysdate, dat_zapisu) <= 24 from student;
--6. Vygenerujte prÌkazy na pridanie pr·v create any directory osobe, ktor· v nejakom roku ötudovala nejak˝ predmet
select 'grant create any directory to ' || os_cislo || ';' from (select distinct os_cislo from zap_premdety);
