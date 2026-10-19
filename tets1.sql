--aggregacne funkcie json agg, json obeject agg, json array
select json_arrayagg(json_object('meno' value meno,
                    'priezvisko' value priezvisko,
                    'rod_cislo' value rod_cislo,
                    'psc' value m.psc))
    ,m.psc as psc_mesto, m.n_mesta as n_mesta
                    from soc_poistovna.p_osoba o
                    join soc_poistovna.p_mesto m on (m.psc = o.psc)
                    group by m.psc, m.n_mesta;
                    
select json_value(json_data, '$.meno'),
    json_value(json_dta, '$.priezvisko')
        from mesta_json_tab;
select json_value(json_data, '$[1].meno'),
    json_value(json_dta, '$.priezvisko')
        from mesta_json_tab;

--pre kazdy rok osobitne vypisat pocet novych poberatelov zien a muzov osobitne
select count(case when (substr(rod_cislo, 3, 1) >= 5)
        then 1 else null end) as pocet_zien,
        count(case when (substr(rod_cislo, 3, 1) < 5)
        then 1 else null end) as pocet_zien,
        count(rod_cislo), to_char(dat_od, 'YYYY') from soc_poistovna.p_poberatel group by to_char(dat_od, 'YYYY');

--ziskat 10 percent ludi co ziskali najviac na prispevkoch

select * from (select id_poberatela, sum(suma) as sumicka, row_number() over(order by sum(suma) desc) as poradie
                from soc_poistovna.p_prispevky group by id_poberatela)
    where poradie <= (select count(id_poberatela)*0.1 from soc_poistovna.p_poberatel);
    
    
--10 skupin co najviac rovnomerne rozdelenych
select p.*, trunc(poradie/10)+1 skupina
    from (select id_poberatela, row_number() over(order by dat_od desc)-1 as poradie from soc_poistovna.p_poberatel)
    p;
    
--objektovy typ ktore uchovava meno, priezvisko, rod cislo, id zamestna

create or replace type t_zamestnanci as object (
    meno varchar2(50),
    priezvisko varchar2(50),
    rod_Cislo varchar2(11),
    id_zamestnavatela varchar2(11),
    member function je_dochodca return char
);
/
create or replace type body t_zamestnanci is 
member function je_dochodca return char 
is
    vek int;
    current_year int;
begin
    current_year := extract(year from sysdate);
    vek := current_year - '19' || substr(rod_cislo, 1, 2);
    if vek >= 60
    then return 'A';
    else return 'B';
    end if;
end;
end;
/
create or replace type t_kolekcia_zam is table of t_zamestnanci;
/
create table zamestnanci_nt
(
ico char(11),
nazov varchar(30),
kolekcia t_kolekcia_zam
) nested table kolekecia store as kolekcia_inner_tab;

select ico, nazov, listagg(rod_cislo || ' ' || dat_od, ',') from soc_poistovna.p_zamestnavatel a left join soc_poistovna.p_zamestnanec b on (a.ico = b.id_zamestnavatela)
    group by ico, nazov;
    
--pre vsetky zeny vypisat 
select add_months(sysdate, 1) from dual;
