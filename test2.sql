--vypÌsaù ötudentov s najviac zÌskan˝mi bodmi podæa öt˙dijnÈho programu

with top_student as (select os_cislo, st_odbor, sum(ects) as kredity from zap_predmety join student using (os_cislo) 
    where vysledok is not null group by os_cislo, st_odbor)
, top_kredity as (select max(kredity) as maximum, st_odbor from top_student group by st_odbor)
select os_cislo, st_odbor from top_student join top_kredity using (st_odbor) where maximum = kredity; 

select os_cislo, st_odbor from (select os_cislo, st_odbor, dense_rank() over (partition by st_odbor order by kredity desc) as rnk from (select os_cislo, st_odbor, sum(ects) as kredity from zap_predmety join student using (os_cislo) 
    where vysledok is not null group by os_cislo, st_odbor))
        where rnk = 1;
        
-- predmet, ktor˝ bol najmenej vyberan˝ ötudentami zo öt˙dijn˝ch programov / odborov (ber˙ sa aj predmety, ktorÈ nemali zapÌsan˝ch ûiadnych ötudentov)

select st_odbor, cis_predm, dense_rank() over (partition by st_odbor order by zapisani asc) from
(select cis_predm, st_odbor, count(*) as zapisani from predmet left join zap_predmety using (cis_predm) left join student using (os_cislo) group by cis_predm, st_odbor);

-- Pre kaûd˝ roËnÌk vypÌsaù 10 % ötudentov s najhoröÌmi zn·mkami (podæa priemeru zn·mok).

with priemery as (select os_cislo, avg(case vysledok
        when 'A' then 1.0
        when 'B' then 1.5
        when 'C' then 2.0
        when 'D' then 2.5
        when 'E' then 3.0
        else 5.0
        end) as priemer from zap_predmety where vysledok is not null group by os_cislo),
statistiky as (select os_cislo, rocnik, priemer from student join priemery using (os_cislo))
select rnk, os_cislo, rocnik from (select dense_rank() over (partition by rocnik order by priemer asc) as rnk, os_cislo, rocnik from statistiky) stat
where rnk <= (select (count(*)/10)+1 from student stud where stud.rocnik = stat.rocnik) order by rocnik;

--VypÌöte vöetky poistenia (stÂpce id_poistenca, rod_cislo, id_platitela) a v prÌpade, ûe je platba nad 100Ä tak aj info o platbe (stÂpce cis_platby, suma)
 
-- Vygenerujte prÌkazy na pridanie pr·v create any directory osobe, ktor· v nejakom roku ötudovala nejak˝ predmet

-- xml root -> formatovanie a kontrola validnosti
select xmlroot(xmlelement("osoba", 
                        xmlattributes(os.rod_cislo as rc),
                        xmlelement("meno", meno),
                        xmlelement("priezvisko", priezvisko), 
                        xmlelement("datum_zapisu", dat_zapisu)
                    
                ), version '1.0') as xml
from os_udaje os
join student st on os.rod_cislo = st.rod_cislo;

desc os_udaje;

select xmlroot (xmlelement("osoba", 
                            xmlattributes(os.rod_cislo as rc),
                            xmlforest(meno as "meno",
                                        priezvisko as "priezvisko",
                                        st.dat_zapisu as "datum_zapisu")), version no value) as xml
from os_udaje os
join student st on os.rod_cislo = st.rod_cislo;

select xmlroot (xmlelement("osoby", 
                            xmlelement("osoba", 
                                xmlattributes(os.rod_cislo as rc),
                                xmlforest(os.meno as "meno",
                                        os.priezvisko as "priezvisko",
                                        to_char(st.dat_zapisu, 'DD.MM.YYYY') as "datum_zapisu"),
                                        xmlagg(xmlelement("Predmety", pr.nazov))
                            )), version no value)
from os_udaje os
join student st on os.rod_cislo = st.rod_cislo
join zap_predmety zp on st.os_cislo = zp.os_cislo
join predmet pr on zp.cis_predm = pr.cis_predm
group by os.rod_cislo, meno, priezvisko, st.dat_zapisu;

create table poberatelia_xml of xmltype;

insert into poberatelia_xml
values (xmlroot(
        xmlelement("poberatel",
                    xmlattributes('1' as "id",
                    '991212/1234' as "rod_cislo"),
                    xmlelement("meno", 'Ado'),
                    xmlelement("priezvisko", 'Maini')
                    ),
                    version '1.0' -- alebo no value co je default
                    ));
                    
select * from poberatelia_xml;

create table xml_stud of xmltype;

insert into xml_stud
select xmlroot(xmlelement("osoby", 
                            xmlelement("osoba",
                                        xmlattributes(os.rod_cislo as rc), 
                                        xmlforest(os.meno as "meno",
                                                    os.priezvisko as "priezvisko",
                                                    to_char(st.dat_zapisu, 'DD.MM.YYYY') as "datum_zapisu"
                                                    ), xmlagg(xmlelement("Predmety", pr.nazov))
                                                    )), version no value)
from os_udaje os
join student st on os.rod_cislo = st.rod_cislo
join zap_predmety zp on st.os_cislo = zp.os_cislo
join predmet pr on zp.cis_predm = pr.cis_predm
group by os.rod_cislo, meno, priezvisko, st.dat_zapisu;

select * from xml_stud;
drop table predmet_xml;
create table predmet_xml
(
    predmet_id INT primary key,
    nazov varchar(100),
    ucitel_xml xmltype,
    constraint chk_ucitel_xml check (ucitel_xml is not null)
);

insert into predmet_xml (predmet_id, nazov, ucitel_xml)
values (1, 'Programovanie', 
        xmlroot (
                xmlelement("ucitel",
                            xmlattributes('1' as "id"),
                            xmlelement("meno", 'Jozef'),
                            xmlelement("priezvisko", 'Novak')
                            ),
                            version '1.0' 
                    ));
                    
select * from predmet_xml;

select x.krstne_meno
from predmet_xml p,
    xmltable('/ucitel'
            passing p.ucitel_xml
            columns
                krstne_meno varchar2(50) path 'meno') x
where predmet_id = 1;



select x.id
from predmet_xml p,
    xmltable('/ucitel'
            passing p.ucitel_xml
            columns
            --nazov stlpca a cesta k atributu - takze @
            id varchar2(50) path '@id') x
where predmet_id = 1;

select extractvalue(ucitel_xml, '/ucitel/meno') as krstne_meno
from predmet_xml
where predmet_id = 1;
select extractvalue(ucitel_xml, '/ucitel/meno') as krstne_meno
from predmet_xml
where extractvalue(ucitel_xml, '/ucitel/@id') = 1;

update predmet_xml
set ucitel_xml = updatexml(ucitel_xml, '/ucitel/meno/text()', 'Karol')
where predmet_id = 1; -- prekrstenie Joza na Karola

select * from predmet_xml;

select xmlroot (xmlelement("osoby", 
                    xmlagg(
                            xmlelement("osoba", 
                                xmlattributes(os.rod_cislo as rc),
                                xmlforest(os.meno as "meno",
                                        os.priezvisko as "priezvisko",
                                        os.ulica as "ulica",
                                        to_char(st.dat_zapisu, 'DD." "Month YYYY') as "datum_zapisu")
                            ))), version no value)
from os_udaje os
join student st on os.rod_cislo = st.rod_cislo
join zap_predmety zp on st.os_cislo = zp.os_cislo
join predmet pr on zp.cis_predm = pr.cis_predm
group by os.rod_cislo, meno, priezvisko, ulica, st.dat_zapisu;

declare type t_pole IS TABLE OF integer;
pole t_pole;
begin
pole:=t_pole(10,20,30,40,50,60,70);
pole.delete(4);

dbms_output.put_line(pole.last);
dbms_output.put_line(pole.count);
dbms_output.put_line(pole(pole.next(3)));
dbms_output.put_line(pole(pole.next(2)));
end;
/
declare type t_pole is table of integer;
i integer;
pole t_pole;
j integer;
begin
pole := t_pole(1,2,3,4,5,6,7,8);
pole.delete(3);
j := pole.first;
for i in 1 .. pole.count loop
dbms_output.put_line(pole(j));
j := pole.next(j);
end loop;
end;
/
-- VypÌöte 5% obyvateæov s najv‰ËöÌmi odvodmi do poisùovne pre kaûdÈ mesto osobitne. (3 b):
with mesta as (select psc from p_mesto)

select rnk, n_mesta, rod_cislo from (select dense_rank() over (partition by n_mesta order by sumicka desc) as rnk, n_mesta, rod_cislo from (select rod_cislo, n_mesta, sum(p_odvod_platba) as sumicka 
    from p_positenie join p_odvod_platba using (id_poistenca) join p_osoba using (rod_cislo) join p_mesto using (psc) group by rod_cislo, n_mesta)) kaka
    where rnk <= 
    (select pocet from (select (count(*)*0.05 + 1) as pocet, n_mesta from p_osoba join p_mesto using (rod_cislo) group by n_mesta) jaja where kaka.n_mesta = jaja.n_mesta) ;
select;
-- Vygenerujte prÌkazy na pridanie pr·v create any directory osobe, ktor· v nejakom roku ötudovala nejak˝ predmet

declare
    cursor kurzorik is (select 'grant crate any directory to ' || rod_cislo || ';' from (select meno, priezvisko, rod_cislo from os_udaje join student using (rod_cislo) join zap_predmety using (os_cislo) group by meno, priezvisko, rod_cislo));
    retazec varchar(500);
begin
    open kurzorik;
    loop
    fetch kurzorik into retazec;
    exit when kurzorik%notfound;
    dbms_output.put_line(retazec);
    end loop;
    close kurzorik;
end;
/


select * from kvet3.p_typ_prispevku; 