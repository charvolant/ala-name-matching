#How a scientific name is found

Once you have a spanking new index, you can use it to try and match a name to an LSID

Possible parameters:

* name The name (the only thing that's required)
* rank The expected rank of the result
* fuzzy If true, then fuzzy name matches are attempted to try and find something that was misspelled
* ignoreHomonyms If true, 
* kingdom A kingdom hint
* classification A full classification, given names or ids for kingdom through to suspecies, scientific name, authorship and rank. 
The classification can be partially populated, in which case what is available is used.

Here we go ...

##Handling Multiple Matches

If there are multiple matches, the searcher will try to reduce the matches down to a best result.

* Excluded names are removed.
* Misapplied names are removed.
* Split species where parents are listed as synonyms of child species
* Cross-rank homonyms, where a name matches multiple taxa on multiple ranks. These are detected via an
internal list of names, cross_rank_homonyms.txt
* Homonyms at the genus level (with similar-enough authors if the author is available). If there is enough information
available to reduce the homony level, from things like hints or partial classifications, then the single result is
returned.

In these cases, error values are added to the matching metrics, indicating a poor match.
Or, if it's all turned out to be a bit of a disaster, an exception is thrown.

##Exact Match

First attempt is to match the supplied name against the **name** field in the index, optionally annotated
with rank restrictions and classification information.

##Parsed Name

Second attempt is to split the name up into chunks and see whether we can make a match to a [phrase name](glossary#def-phrase-name).
In this case, the match is against **genus**, **specific** (eipthet), **phrase** and **voucher**
If multiple results are returned, but they all refer to the same accepted concept then the accepted concept is used.

##Canoncial Name

Third attempt is to match on a [canonical name](glossary#def-canonical-name).
If the name is a cultivar, then a phrase name match is also tried.

##Soundex Macth

Last attempt is to try and see whether the genus, specific epithet and infraspecific epithet can be
found via sounded.

##Errors

* Searching for something that is a [rank marker](glossary#def-rank-marker) (eg. "sp.") or
multiple species (eg. "spp.") will cause an error.

#How a common name is found

Much easier.
The common name is searched for and, if everything found  points towards the same scientific name, then
that is returned, otherwise nothing is returned.

