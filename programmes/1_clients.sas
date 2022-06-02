/************************* FICHIER_Client ***********************************/
/*Modification le fichier clients (nom de la colonne date_création_compte) on enlève l'accent dans le nom*/
proc import datafile="Projet RFM\donnees\clients.csv" 
		out=clients   /* Nom de la table en sortie */
		dbms=csv      /* Le type de données à importer */
		replace;
	/* A utiliser pour remplacer la table de sortie*/
	delimiter=';';

	/* Le séparateur utilisé */
	getnames=yes;

	/* Prendre la première ligne comme nom de colonnes */
run;

Proc contents data=clients;
run;

proc sql;
	create table audit_client as select count(num_client)as nb_lignes, /*5096*/
	count(distinct(num_client))as nb_num_clients, /*5096*/
	/*Valeurs non renseignées */
	sum(num_client="") as nb_NR_actif, /*0*/
	sum(date_creation_compte=.) as nb_NR_date_creation_compte, /*0*/
	sum (A_ete_parraine=" ") as nb_NR_A_ete_parraine, /*106(beaucoup)*/
	sum (Genre="") as nb_NR_genre, /*0*/
	sum (date_naissance=.) as nb_NR_date_naissance, /*62(beaucoup)*/
	sum (inscrit_NL=.) as nb_NR_inscrit_NL, /*0*/
	/*Peu de variables non renseignées*/
	max (date_creation_compte) as max_date_creation_compte format ddmmyy10., 
		/*26/12/2021*/
		min (date_creation_compte) as min_date_creation_compte format ddmmyy10., 
		/*19/02/2013*/
		max (date_naissance) as max_date_naissance format ddmmyy10., 
		/*18/10/2014 bizarre la personne n'a que 8 ans sachant le site e-commerce*/
		min (date_naissance) as min_date_naissance format ddmmyy10., 
		/*11/05/1930 bizarre la personne a plus de 92 ans */
		/*Quelques incohérance sur les dates de naissance*/
		/*Nombre de modalités des variables */
		count (distinct (Genre)) as nb_D_genre, /*2 variable booléenne*/
		count (distinct (A_ete_parraine)) as nb_D_A_ete_parraine, 
		/*3 modalités pour une variable qui est sensée être booléenne(oui-non-?)*/
		count (distinct (actif)) as nb_D_actif, /*2 variable booléenne très bien*/
		count (distinct (inscrit_NL)) as 
		nb_D_inscrit_NL/*2 variable booléenne donc très bien*/
		from clients;
quit;

proc export data=work.Audit_client 
		outfile="Projet RFM\resultats\tables\1_Audit_client.csv" dbms=csv;
	delimiter=";";
run;

/*On va analyser les modalités de ces variables par des proc freq*/
proc freq data=clients;
	table A_ete_parraine inscrit_NL;
run;

proc freq data=clients;
	table genre;
run;

/*La clientèle est majoritairement féménine plus de 80% */
data clients_MEF;
	set clients;
	age=YEAR(today())-YEAR(date_naissance);
run;

proc export data=work.Clients_mef 
		outfile="Projet RFM\resultats\tables\2_Clients_mef.csv" dbms=csv;
	delimiter=";";
run;

/*Analyse descriptive des clients*/
proc sql;
	create table stat_client as select count(distinct(num_client))as nb_client, 
		/*5096*/
		sum(actif=1)as compte_ouvert, /*5019*/
		sum(inscrit_NL=1)as inscrit_NL, /*4060*/
		sum(Genre="Homme") as Monsieur, /*1015*/
		sum(Genre="Femme") as Madame, /*4081*/
		sum(Genre not in ("Homme", "Femme")) as civilite_NR, /*0*/
		sum((age<=0)+(age>100)) as age_Non_renseigne, /*62*/
		sum(0<age<18) as age_Moins_de_18_ans, /*56*/
		sum(18<=age<=25) as age_18_25_ans, /*44*/
		sum(25<age<=35) as age_25_35_ans, /*92*/
		sum(35<age<=45) as age_35_45_ans, /*823*/
		sum(45<age<=55) as age_45_55_ans, /*1583*/
		sum(55<age<=65) as age_55_65_ans, /*1290*/
		sum(65<age<100) as age_plus_de_65_ans, /*1146*/
		mean(age) as age_moyen/*55.54 ans */
		from clients_MEF;
quit;

/*Une clientèle plus au moins agée donc sûrement c'est relié aux types et à la catégorie des produits commercialisés*/
proc export data=work.stat_client 
		outfile="Projet RFM\resultats\tables\3_stat_client.csv" dbms=csv;
	delimiter=";";
run;