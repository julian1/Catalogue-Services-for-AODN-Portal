
### Vim

from,
vim /usr/share/vim/vim80/syntax/haskell.vim

:let hs_highlight_delimiters = 1
:let hs_highlight_types = 1
:let hs_highlight_more_types = 1

### Build,

```
apt-get install cabal-install
cabal install hxt
cabal install hxt-curl
cabal install warp
# cabal install warp-tls

# cabal install http-client
cabal install http-client-tls
cabal install raw-strings-qq

apt-get install libpq-dev
cabal install postgresql-simple

```


### create the db
```
psql -h postgres.localnet -U admin -d postgres -f create-db.sql
psql -h postgres.localnet -U harvest -d harvest -f views.sql
```


#### refs


- postgresql simple
  https://hackage.haskell.org/package/postgresql-simple-0.5.2.1/docs/Database-PostgreSQL-Simple.html

- parameter vocabulary
  https://s3-ap-southeast-2.amazonaws.com/content.aodn.org.au/Vocabularies/parameter-category/aodn_aodn-parameter-category-vocabulary.rdf

-- CSW GetCapabilities
-- https://catalogue-portal.aodn.org.au/geonetwork/srv/eng/csw?request=GetCapabilities&service=CSW

-- Good CSW examples,
-- https://gist.github.com/kalxas/5ab6237b4163b0fdc930

-- has PointOfTruth and OnlineResourceType 




### Old - Notes, on libraries

http-client 
    https://haskell-lang.org/library/http-client 
    - minimalistic - no ssl/https support
    - someone else says it does have tls 

http-client-tls
    - has tls. 

http    
    https://hackage.haskell.org/package/HTTP 
    - no https - "NOTE: This package only supports HTTP; it does not support HTTPS. Attempts to use HTTPS result in an error."
    - cabal install http-conduit 
    - absolutely huge


warp
    The biggest issue with warp-tls has nothing to do with performance, but that it uses an obscure TLS implementation that has received fairly little review, and almost certainly has bugs. 
    but It has gotten top marks in every audit. We are comfortable with relying on it in production. If the alternative is an OpenSSL-based implementation,

wreq - 
    supposedly simple
    uses lenses.




