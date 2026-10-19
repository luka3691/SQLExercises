--zakaladne formatovanie
select xmlroot(xmlelement("osoba",
                    xmlattributes(rod_cislo as rc),
                    xmlelement("meno", meno),
                    xmlelement("priezvisko", priezvisko),
                    xmlelement("datum_narodenia", (sysdate - substr(rod_cislo, 1, 2))) --maju vlastny format datumov (pouzivat extract alebo to_char)
                    ), version no value) as xml from os_udaje;
--rozdiel medzi forest a klasickym
select xmlroot(xmlelement("osoba",
                    xmlattributes(rod_cislo as rc),
                    xmlforest(meno as "meno",       
                              priezvisko as "priezvisko",
                              (sysdate - substr(rod_cislo, 1, 2)) as "datum_narodenia"
                              )
                    ), version no value) as xml from os_udaje;

select xmlroot(xmlelement("osoba",
                    xmlattributes(rod_cislo as rc),
                    xmlforest(meno as "meno",       
                              priezvisko as "priezvisko",
                              to_char((sysdate - substr(rod_cislo, 1, 2)), 'DD.MM.YYYY') as "datum_narodenia"
                              )
                    ), version no value) as xml from os_udaje;

select xmlroot(xmlelement("osoba",
                    xmlattributes(rod_cislo as rc),
                    xmlforest(meno as "meno",       
                              priezvisko as "priezvisko",
                              (sysdate - substr(rod_cislo, 1, 2)) as "datum_narodenia"
                              ), xmlagg(xmlelement("Platby", cis_platby)) --iba pocet keby tam nie agg
                    ), version no value) as xml from soc_poistovna.p_osoba join soc_poistovna.p_poistenie using (rod_cislo) join soc_poistovna.p_odovod_platba using (id_poistenca)
                        group by rod_cislo, meno, priezvisko;
                        
                        --
create table poberatelia_xml of xmltype;
insert into poberatelia_xml values (
    xmlroot(
    xmlelement("poberatel",
                xmlattributes('1' as "id",
                                '840705/8473' as "rod-cislo"),
                xmlelement("meno", 'Andrej'),
                xmlelement("priezvisko", 'Fila'))
    , version '1.0')
);

select * from poberatelia_xml;

create table xml_stud of xmltype;
insert into xml_stud (select xmlroot(xmlelement("student", xmlattributes(os_cislo as "osobne"), xmlelement("sukromne", xmlforest(meno, priezvisko, rod_cislo))), version 1.0) xml from student join os_udaje using (rod_cislo));

select xmlelement( "Osoba", xmlattributes(os.rod_cislo as rc),
                            xmlelement("MenoPriezvisko",
                                xmlattributes(os.priezvisko as pz), meno || ' ' || priezvisko),
                            xmlelement("Rod_cislo", os.rod_cislo)
        ) as xmlko
from os_udaje os;

--vytvorenie tabulky pre predmety s xmltype atributom
create table predmet_xml(
    predmet_id int primary key,
    nazov varchar(100),
    ucitel_xml xmltype,
    constraint chk_ucitel_xml check (ucitel_xml is not null)
);
select * from predmet_xml;

insert into predmet_xml (predmet_id, nazov, ucitel_xml) values (1, 'Programovanie',
    xmlroot(
        xmlelement("ucitel",
        xmlattributes('1' as "id"),
        xmlelement("meno", 'Jozef'),
        xmlelement("priezvisko", 'Novak')
        ), version '1.0'
    )
);

select extractvalue(ucitel_xml, '/ucitel/meno') from predmet_xml;
select value(x) from predmet_xml x;
select x.getClobVal() from predmet_xml x;

select x.krstne_meno from predmet_xml p, 
                        xmltable( '/ucitel'
                                passing p.ucitel_xml
                                columns
                                krstne_meno varchar2(50) path 'meno'
                        ) x
    where predmet_id = 1;
    
--aktualizacia tabulky

update predmet_cml
set ucitel_xml = updatexml(ucitel_xml, '/ucitel/meno/text()', 'Karol')
where predmet_id = 1;

--aktualizacia tabulky xml typu
select value(x) from xml_stud x ;
update xml_stud
set object_value = updateXML(object_value, '//MENO/text()', 'Adam')
where extractValue(object_value, '//MENO') = 'Peter' ;

select extractValue(value(p), '//MENO') as menopriezvisko
from xml_stud p where extractValue(value(p), '//MENO') = 'Peter';
select extractValue(value(p), '//MENO') as menopriezvisko
from xml_stud p where extractValue(value(p), '/student/@osobne') = '501103';
select value(x) from xml_stud x;
--cyklicka referencia
--na co su dobre konstrainy

select xmlroot(xmlelement ("osoby", xmlagg(xmlelement("osoba",
                    xmlattributes(rod_cislo as rc),
                    xmlforest(meno as "meno",       
                              priezvisko as "priezvisko"),
                              xmlelement("ulica", ulica),
                    xmlforest(to_char((sysdate - substr(rod_cislo, 1, 2)), 'DD.month.YYYY') as "datum_narodenia"
                              )--, xmlagg(xmlelement("Platby", cis_platby)) --iba pocet keby tam nie agg
                    ))), version no value) as xml from os_udaje ;