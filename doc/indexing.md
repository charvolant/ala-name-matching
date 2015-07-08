#How an index is generated

This covers how an index is generated from individual files.
How an index is generated from a DwCA ... to come.

##Source information

The index is generated from a number of supplied files. These are either found in `/data/bie-staging/ala-names` or `/data/bie-staging/anbg`.

* known_homonyms.txt (internal) A list of words that are [homonyms](glossary#def-homonym). Not currently used.
* blacklist.txt (internal) A list of names that should not be included in the index.
* ala_accepted_concepts_dump.txt (default in bie-staging)  A list of accepted names
* ala-extra.txt (default in bie-staging) A list of additional taxa to add to the index, somewhat more limited than the accepted concepts
* ala_synonyms_dump.txt (default in bie-staging) A list of synonyums
* col_common_names.txt (default in bie-staging) A list of collection-supplied common names
* identifiers.txt (default in bie-staging) A list of lsid onto "real" lsid mappings, so that common names, synonyms etc. can be correctly resolved.
Note that this needs to be generated as an input file.
* IRMNG_DWC_HOMONYMS The base directory of a DwCA containing [homonyms](glossary#def-homonym)
* ala-species-homonyms.txt (default in bie-staging) The ALA list of homonyms (species only)
* AFD-common-names.csv (default in bie-staging) Common names from the AFD
* APNI-common-names.csv (default in bie-staging) Common names from APNI

###ala_accepted_concepts_dump.txt

A CSV file with the following columns

1. identfier
1. parent identifier (not used)
1. [lsid](glossary#def-lsid)
1. parent lsid (not used)
1. [accepted name](glossary#def-accepted-name)
1. accepted name id
1. name lsid (not used)
1. scientific name
1. genus or higher taxon name (not used)
1. specific epithet
1. infraspecific eipthet
1. author
1. authorship year
1. rank id
1. rank name
1. left
1. right
1. kingdom id
1. kingdom name
1. phylum id
1. phylum name
1. class id
1. class name
1. order id
1. order name
1. family id
1. family name
1. genus id
1. genus name
1. species id
1. species name
1. source
1. [excluded](glossary#def-excluded) flag

The left and right values do what??

###ala-extra.txt

A CSV file with the following columns:

1. lsid
1. scientific name
1. author

###ala_synonyms_dump.txt

A CSV file with the following columns

0. id
1. lsid
2. name lsid
3. accepted lsid
4. accepted id
5. scientific name
6. author
7. ?
9. synonym type
10. ?
11. ?
12. source

###col_common_names.txt

A CSV file with the following columns

0. common name
1. scientific name
2. lsid

###IRMNG_DWC_HOMONYMS

A [Darwin core archive][DwCA] that contains a list of [homonyms](glossary#def-homonym).
This has a list of names: kingdom, phylum, class, order, family, genus, species, rank, author.

###ala-species-homonyms.txt

A CSV file that contains a list of homonyms known to the ALA:

0. kingdom
1. phylum
2. class
3. order
4. family
5. genus
6. genus id or species
7. ?
8. synonym
9. ?
10. homonym

###AFD-common-names.csv and APNI-common-names.csv

CSV files that contain additional common names:

0. ?
1. ?
2. common name, possibly a list separated by commas
3. lsid
 

##Index Documents

Index documents are lucene documents that allow searching for taxa.
Each document contains a collection of data in the form of named fields.
These fields are (mostly) indexed when the document is added to the lucene index.

###Taxon Concept/Name

Documents of this sort record both synonyms and accepted names:

* id The supplied identifier for the name
* lsid The [lsid](glossary#def-lsid) for the name
* ala If T then the lsid is an internal ALA guid
* name The supplied scientific name. 
* name The canonical scientific name, if available.
* name The virus name without the "virus" qualifier, if a virus
* specific The canonical specific epithet, if available
* phrase The cleaned up [phrase name](glossary#def-phrase-name) identifier, if available
* voucher The cleaned up [phrase name](glossary#def-phrase-name) [voucher](glossary#def-voucher), if available
* rank_id The rank identifier
* rank The rank name
* is_synonym Whether this is a synonym of another name (T/F)
* synonym_type The synonym type. (always set to *excludes* if this is an excluded name)
* accepted If this is a synonym, then this is the id of the [accepted name](glossary#def-accepted-name)
* kingdom The kingdom name
* kid The kinddom id
* phylum The phylum name
* pid The phylum id
* class The class name
* cid The class id
* order The order name
* oid The order id
* family The family name
* fid The family id
* genus The genus name
* genus The genus name as supplied by a [phrase name](#def-phrase-name)
* genus_ex The [soundexed][soundex] genus name
* gid The genus id
* species The species name
* species_ex The [soundexed][soundex] specific epithet
* infra_ex The [soundexed][soundex] infraspecific epithet
* sid The species id
* left The left value
* right The right value
* author The author

Names have a [boost](http://lucene.apache.org/core/5_2_0/core/org/apache/lucene/search/package-summary.html#package_description) attached 
to them which emphasises names attached to the major taxon ranks, names from non-collection sources (ie the NSL) and a few other
criteria.

###Common name

* common_name The supplied common name
* name The scientific name
* lsid The lsid of the matching accepted taxon concept/name.
A common name that maps onto a synonym lsid will have the lsid replaced by the accepted taxon lsid

###Homonym

An index of homonyms

* kingdom The kingdom name
* phylum The phylum name
* class The class name
* order The order name
* family The family name
* genus The genus name
* species The species name
* rank The homonym rank
* author The author, if available
* synonym The genus this is a synonnym of, for genus-level homonyms
* homonym The genus this is a homonym of, for genus-level homonyms
* id The genus id, for genus-level homonyms

##References

[DwCA]: https://code.google.com/p/gbif-ecat/wiki/DwCArchive
[soundex]: https://en.wikipedia.org/wiki/Soundex Soundex Algorithm