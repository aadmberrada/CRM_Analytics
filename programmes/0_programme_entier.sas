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

/************************* FICHIER_Commande ***********************************/
data commandes;
	infile 'Projet RFM\donnees\commandes.csv' delimiter=";" missover dsd 
		firstobs=2;
	format date $10.;
	format num_client $9.;
	input num_client $    
    numero_commande date $    
    montant_des_produits remise_sur_produits montant_livraison 
		remise_sur_livraison montant_total_paye;
run;

/*convertir la colonne date déclarée comme chaîne de caractère en format date*/
data commande;
	set commandes;
	jour=Substr(date, 1, 2);
	month=Substr(date, 3, 5);
	annee=Substr(strip(reverse(date)), 1, 2);
	annee=strip(reverse(annee));

	if month="-janv" then
		mois="/01/";
	else if Substr(month, 1, 2)="-f" then
		mois="/02/";
	else if month="-mars" then
		mois="/03/";
	else if month="-avr-" then
		mois="/04/";
	else if month="-mai-" then
		mois="/05/";
	else if month="-juin" then
		mois="/06/";
	else if month="-juil" then
		mois="/07/";
	else if month="-aout" then
		mois="/08/";
	else if month="-sept" then
		mois="/09/";
	else if month="-oct-" then
		mois="/10/";
	else if month="-nov-" then
		mois="/11/";
	else if Substr(month, 1, 2)="-d" then
		mois="/12/";
	date2=compress(jour||mois||annee);
	date_=input(strip(date2), ddmmyy10.);
	format date_ ddmmyy10.;
	drop jour mois annee month date2;
RUN;

Proc contents data=commande;
run;

*On est bon, aucune valeur manquante dans la date_ et elle est déclarée comme variable numérique ;

proc sql;
	create table audit_commande as select count (numero_commande) as nb_ligne, 
		/*11242*/
		count (distinct (numero_commande)) as NB_commandes, /*11242*/
		/*Une commande par ligne*/
		count (distinct (num_client)) as NB_num_client, /*4201*/
		/*Le nombre de  numéros de clients est inférieur aux nombre de clients dans le fichiers client*/
		min (date_) as min_date format ddmmyy10., /*01/01/2020*/
		/*Dans pour le périmètre de l'étude on est obligé de commencer par 2020 et pas avant car pas de données dispo pour les commandes*/
		max (date_) as max_date format ddmmyy10., /*31/12/2021*/
		min (montant_des_produits) as min_montant_des_produits, /*3.5*/
		max (montant_des_produits) as max_montant_des_produits, /*3631*/
		min (remise_sur_produits) as min_remise_sur_produits, /*-1396*/
		max (remise_sur_produits) as max_remise_sur_produits, /*7.54*/
		/*C'est très peu comme valeur*/
		min (montant_livraison) as min_montant_livraison, /*0.09*/
		max (montant_livraison) as max_montant_livraison, /*130*/
		min (remise_sur_livraison) as min_remise_sur_livraison, /*-130*/
		max (remise_sur_livraison) as max_remise_sur_livraison, /*35*/
		min (montant_total_paye) as min_montant_total_paye, /*-3.99*/
		max (montant_total_paye) as max_montant_total_paye /*3716*/
		from commande;
quit;

/*Alternance de valeurs négatives et positives sur les montants de remise et de livraison : remboursement*/
proc export data=work.audit_commande 
		outfile="Projet RFM\resultats\tables\4_audit_commande.csv" dbms=csv;
	delimiter=";";
run;

/***************************** Analyse_RFM *************************************
Périmètre d'étude :
Analyse de 2 ans (commandes 2020-2021)
Indicateurs RFM :
Récence: durée en mois entre la date du dernier achat et le 31 décembre 2021
Fréquence : Nombres de commandes passées au cours des 2 dernières années (1 janvier 2020 au 31 décembre 2021)
Montant: Montant moyen (par client) des commandes sur la période d'analyse(il faut le justifier)
*/
proc sql;
	create table indicateur_RFM as select num_client, min (month(date)) as 
		recence, count (distinct (numero_commande)) as frequence, 
		mean (montant_total_paye) as montant from commande where 
		2020<=year(date)<=2021 group by num_client;
quit;

proc export data=work.indicateur_RFM 
		outfile="Projet RFM\resultats\tables\5_indicateur_RFM.csv" dbms=csv;
	delimiter=";";
run;

proc freq data=indicateur_RFM;
	table recence;
run;

/*Il faut trouver les seuils (à priopi 3)*/
proc freq data=indicateur_RFM;
	table frequence;
run;

/*3 seils très clairs F1  =seuil 1 /F2 et F3 sont seuil 2 et le reste seuil 3 */
/*création d'une variable rang (à partir des montants) en 10 groupes*/
proc rank data=indicateur_RFM out=Rang_montant groups=10;
	var montant;
	ranks rang;
run;

/*Analyse des seuils min et max pour chaque rang (proc summary)*/
/* on aurait pu faire une proc sql*/
proc summary data=Rang_montant;
	class rang;
	var montant;
	output out=montant_10_RANG min=montant_min max=montant_max;
run;

/*(3groupes)en générale les 4 premiers 50 euro  puis de 4 à 8 (106 euro)puis le reste 3ème groupe*/
/*M1 = 50 euro
M2 = 50-100 euro
M3 = plus de 100 euro */
proc export data=work.montant_10_RANG 
		outfile="Projet RFM\resultats\tables\6_montant_10_RANG.csv" dbms=csv;
	delimiter=";";
run;

/********************************* Constuction de la segmentation **************************/
/*application des seuils RFM*/
Data application_seuil;
	set indicateur_RFM;

	if 6<recence then
		seg_recence="R1";
	else if 2<recence<=6 then
		seg_recence="R2";
	else if recence<=2 then
		seg_recence="R3";
	else
		seg_recence="?";

	if frequence=1 then
		seg_frequence="F1";
	else if 2<=frequence<=3 then
		seg_frequence="F2";
	else if 3<frequence then
		seg_frequence="F3";
	else
		seg_frequence="?";

	if montant<50 then
		seg_montant="M1";
	else if 50<=montant<100 then
		seg_montant="M2";
	else if 100<=montant then
		seg_montant="M3";
	else
		seg_montant="?";
run;

proc export data=work.application_seuil 
		outfile="Projet RFM\resultats\tables\7_application_seuil.csv" dbms=csv;
	delimiter=";";
run;

/*Vérifier la distribution de ces variables*/
proc freq data=application_seuil;
	table seg_recence seg_frequence seg_montant;
run;

/*résultat parfait*/
/*Croissement de la récence et de la fréquence et construction du groupe RF*/
/*Analyser la distribution du croissement des segments et de récence et de fréquence*/
proc freq data=application_seuil;
	table seg_recence*seg_frequence/out=croisement_recence_frequence;
run;

/*Création de la table application_seuil_RF avec une variable supplémentaire liée à l'application des seuils issus des regroupement RF*/
Data application_seuil_RF;
	set application_seuil;

	if (seg_recence="R1" and seg_frequence="F1") or (seg_recence="R1" and 
		seg_frequence="F2") then
			seg_RF="RF1";
	else if (seg_recence="R1" and seg_frequence="F3") or (seg_recence="R2" and 
		seg_frequence="F1") or (seg_recence="R2" and seg_frequence="F2") 
		or (seg_recence="R3" and seg_frequence="F1") then
			seg_RF="RF2";
	else if (seg_recence="R2" and seg_frequence="F3") or (seg_recence="R3" and 
		seg_frequence="F2") or (seg_recence="R3" and seg_frequence="F3") then
			seg_RF="RF3";
	else
		seg_RF="?";
run;

proc export data=work.application_seuil_RF 
		outfile="Projet RFM\resultats\tables\8_application_seuil_RF.csv" dbms=csv;
	delimiter=";";
run;

/*Analyser la distribution de la variable seg_RF*/
proc freq data=application_seuil_RF;
	table seg_RF;
run;

/*Analyser la distribution du croissement des segments RF et montant */
Proc freq data=application_seuil_RF;
	table seg_RF* seg_montant/out=croisement_RF_montant;
run;

/*On définit les 9 groupes RFM */
Data segment_RFM;
	set application_seuil_RF;

	if seg_RF="RF1" and seg_montant="M1" then
		seg_RFM="RFM1";
	else if seg_RF="RF1" and seg_montant="M2" then
		seg_RFM="RFM2";
	else if seg_RF="RF1" and seg_montant="M3" then
		seg_RFM="RFM3";
	else if seg_RF="RF2" and seg_montant="M1" then
		seg_RFM="RFM4";
	else if seg_RF="RF2" and seg_montant="M2" then
		seg_RFM="RFM5";
	else if seg_RF="RF2" and seg_montant="M3" then
		seg_RFM="RFM6";
	else if seg_RF="RF3" and seg_montant="M1" then
		seg_RFM="RFM7";
	else if seg_RF="RF3" and seg_montant="M2" then
		seg_RFM="RFM8";
	else if seg_RF="RF3" and seg_montant="M3" then
		seg_RFM="RFM9";
	else
		seg_RFM="?";
run;

proc export data=work.segment_RFM 
		outfile="Projet RFM\resultats\tables\9_segment_RFM.csv" dbms=csv;
	delimiter=";";
run;

/*Analyse de la distribution par segment*/
Proc freq data=segment_RFM;
	table seg_RFM;
run;