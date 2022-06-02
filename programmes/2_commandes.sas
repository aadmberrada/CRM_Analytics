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