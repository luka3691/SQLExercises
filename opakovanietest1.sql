--vhodny prikaz na ziskanie podstromu xml dokumentu
SELECT EXTRACT(xml_data, '/poberatel/pob_prispevky/prispevok[1]') AS prispevok
FROM xml_tab_prispevky
WHERE id = 1;

--update table(select historia from p_typ_prispevku where id_typu = 2) set;
/
select xmlroot(xmlelement("osoba",xmlattributes(rod_cislo as rc), xmlagg(xmlelement("vsetkyidcka", xmlattributes(id_poberatela as id_poberatela)))), version no value) as xml from soc_poistovna.p_osoba join soc_poistovna.p_poberatel using (rod_cislo) group by rod_cislo;

SELECT 
    tp.nazov_postihnutia,
    SUM(CASE WHEN extract(day from p.dat_od) <= 7 THEN 1 ELSE 0 END) AS "1. t˝ûdeÚ",
    SUM(CASE WHEN extract(day from p.dat_od) between 8 and 14 THEN 1 ELSE 0 END) AS "2. t˝ûdeÚ",
    SUM(CASE WHEN extract(day from p.dat_od) between 15 and 21 THEN 1 ELSE 0 END) AS "3. t˝ûdeÚ",
    SUM(CASE WHEN extract(day from p.dat_od) between 22 and 28 THEN 1 ELSE 0 END) AS "4. t˝ûdeÚ",
    SUM(CASE WHEN extract(day from p.dat_od) between 29 and 31 THEN 1 ELSE 0 END) AS "5. t˝ûdeÚ"
from soc_poistovna.p_ZTP p
join soc_poistovna.p_typ_postihnutia tp using(id_postihnutia)
where 
to_number(substr(p.rod_cislo,3,1)) > 1 and
extract(year from p.dat_od) = 2010
and extract(month from p.dat_od) = 1
group by tp.nazov_postihnutia;

select h.zakl_vyska from table(SELECT p.historia FROM soc_poistovna.p_typ_prispevku p WHERE p.id_typu = 1) h;
SELECT h.zakl_vyska
FROM soc_poistovna.p_typ_prispevku p, TABLE(p.historia) h
WHERE p.id_typu = 1;

-- VypÌöte 5% obyvateæov s najv‰ËöÌmi odvodmi do poisùovne pre kaûdÈ mesto osobitne. (3 b):
select n_mesta, rod_cislo, sumicka, rk from (
select n_mesta, rod_cislo, sumicka, rank() over (partition by n_mesta order by sumicka) rk from 
    (select rod_cislo, n_mesta, sum(suma) as sumicka 
    from soc_poistovna.p_poistenie join soc_poistovna.p_odvod_platba using (id_poistenca) 
    join soc_poistovna.p_osoba using (rod_cislo) 
    join soc_poistovna.p_mesto using (psc) 
        group by rod_cislo, n_mesta)) e
        where rk <= (select trunc(count(*)*0.05) from soc_poistovna.p_osoba f join soc_poistovna.p_mesto g using (psc) where n_mesta = e.n_mesta);
SELECT mesto, meno, priezvisko FROM
(SELECT n_mesta mesto, meno, priezvisko, RANK() OVER (PARTITION BY n_mesta ORDER BY suma DESC) poradie
FROM
(SELECT n_mesta, meno, priezvisko, SUM(suma) suma
FROM p_mesto JOIN soc_poistovna.p_osoba USING (PSC) JOIN soc_poistovna.p_poistenie USING (rod_cislo) JOIN soc_poistovna.p_odvod_platba USING
(id_poistenca)
GROUP BY n_mesta, meno, priezvisko, rod_cislo))
WHERE poradie <= 0.05 * (SELECT COUNT(DISTINCT rod_cislo) FROM soc_poistovna.p_mesto JOIN soc_poistovna.p_osoba USING (PSC) JOIN
soc_poistovna.p_poistenie USING (rod_cislo) JOIN soc_poistovna.p_odvod_platba USING (id_poistenca) WHERE n_mesta = mesto)
;



CREATE TABLE knihy (
    id NUMBER PRIMARY KEY,
    xml_dokument XMLTYPE
);
select xmlroot(xmlelement("knihy" , xmlagg(xmlelement("kniha",
                                xmlattributes(rod_cislo as rc, meno as meno),
                                xmlforest(ulica as "ulica",
                                        psc as "psc")))), version no value) as xml from os_udaje;
                            
select extract(value(s), '/student/meno/text()') from studenti_xml s where ExtractValue(value(s), '/student/@oc')=50043;
INSERT INTO knihy (id, xml_dokument)
VALUES (1, XMLTYPE('
<kniha typ="P" ISBN="978-3-16-148410-0">
    <nazov>Datab·zovÈ systÈmy</nazov>
    <autori>
        <autor poradie="1">
            <meno>Michal</meno>
            <priezvisko>Kvet</priezvisko>
        </autor>
        <autor poradie="2">
            <meno>J·n</meno>
            <priezvisko>Nov·k</priezvisko>
        </autor>
    </autori>
    <fakulta>FRI</fakulta>
</kniha>'));

SELECT id, XMLCAST(XMLQUERY('/kniha/nazov/text()' PASSING xml_dokument RETURNING CONTENT) AS VARCHAR2(100)) AS nazov
FROM knihy
WHERE XMLExists('/kniha[fakulta="FRI"]' PASSING xml_dokument);

SELECT id, XMLCAST(XMLQUERY('/kniha/nazov/text()' PASSING xml_dokument RETURNING CONTENT) AS VARCHAR2(100)) AS nazov
FROM knihy
WHERE XMLExists('/kniha/autori/autor[@poradie="1" and meno="Michal" and priezvisko="Kvet"]' PASSING xml_dokument);

SELECT id, XMLCAST(XMLQUERY('/kniha/nazov/text()' PASSING xml_dokument RETURNING CONTENT) AS VARCHAR2(100)) AS nazov
FROM knihy
WHERE XMLExists('/kniha[@typ="E"]' PASSING xml_dokument);

SELECT 
    XMLCAST(XMLQUERY('/kniha/nazov/text()' PASSING xml_dokument RETURNING CONTENT) AS VARCHAR2(100)) AS nazov,
    XMLCAST(XMLQUERY('/kniha/@ISBN' PASSING xml_dokument RETURNING CONTENT) AS VARCHAR2(20)) AS ISBN,
    XMLCAST(XMLQUERY('/kniha/@typ' PASSING xml_dokument RETURNING CONTENT) AS VARCHAR2(1)) AS typ,
    CASE 
        WHEN XMLExists('/kniha/autori/autor[2]' PASSING xml_dokument)
        THEN XMLCAST(XMLQUERY('/kniha/autori/autor[@poradie="1"]/meno/text()' PASSING xml_dokument RETURNING CONTENT) AS VARCHAR2(50)) 
             || ' ' || XMLCAST(XMLQUERY('/kniha/autori/autor[@poradie="1"]/priezvisko/text()' PASSING xml_dokument RETURNING CONTENT) AS VARCHAR2(50)) || ' (a kol.)'
        ELSE XMLCAST(XMLQUERY('/kniha/autori/autor[@poradie="1"]/meno/text()' PASSING xml_dokument RETURNING CONTENT) AS VARCHAR2(50)) 
             || ' ' || XMLCAST(XMLQUERY('/kniha/autori/autor[@poradie="1"]/priezvisko/text()' PASSING xml_dokument RETURNING CONTENT) AS VARCHAR2(50))
    END AS prvy_autor
FROM knihy;
select n_mesta, sum(CASE WHEN to_char(kedy, 'DD.MM.YYYY') = '16.06.2016' THEN suma ELSE 0 END) AS "16.06.2016",
              sum(CASE WHEN to_char(kedy, 'DD.MM.YYYY') = '17.06.2016' THEN suma ELSE 0 END) AS "17.06.2016",
              sum(CASE WHEN to_char(kedy, 'DD.MM.YYYY') = '18.06.2016' THEN suma ELSE 0 END) AS "18.06.2016"
from soc_poistovna.p_osoba join soc_poistovna.p_mesto using (psc) join soc_poistovna.p_poberatel using (rod_cislo) join soc_poistovna.p_prispevky using (id_poberatela)
    group by n_mesta;
select to_char(kedy, 'DD.MM.YYYY'), sum(suma) from soc_poistovna.p_prispevky where kedy >= to_date('16.06.2016', 'DD.MM.YYYY') and kedy <= to_date('19.06.2016', 'DD.MM.YYYY')
    group by to_char(kedy, 'DD.MM.YYYY');
    
begin
    for i in (select 'userdel ' || rod_cislo as prikaz from tabs)
    loop
        execute immediate i.prikaz;
    end loop;
end;
/

select xmlroot(
        xmlelement("osoby", xmlagg(
                                    xmlforest(p.menucko as "osoba"))),
        xmlelement("mesto", )
        version no value) as xml from 
            (select meno || ' ' || priezvisko as menucko, sum(suma) 
                from soc_poistovna.p_osoba join soc_poistovna.p_mesto using (psc) 
                    join soc_poistovna.p_poberatel using (rod_cislo) 
                        join soc_poistovna.p_prispevky using (id_poberatela)
                group by meno, priezvisko, rod_cislo)p;
                
SELECT 'ALTER TABLE ' || table_name || ' DROP CONSTRAINT ' || constraint_name || ';' AS drop_statement
FROM user_constraints
WHERE table_name = 'P_PRISPEVKY'
  AND constraint_type = 'R';
  
select h.zakl_vyska , h.dat_od, h.dat_do from soc_poistovna.p_typ_prispevku p, table(p.historia) h;

