Haltr - Hackers don't do books

* Create invoices
* Recurring invoices
* Send PDF invoices
* Talk to Bank accounts


about facturae

* http://www.facturae.es/es-ES/Documentacion/EsquemaFormato/Paginas/Index.aspx
* http://www11.mityc.es/FacturaE/ValidarCompleto


INSTALL
-------

* Download Haltr plugin using git

::

  cd <Redmine root dir>/vendor/plugins
  git clone git://github.com/descala/haltr.git

* Install necessary gems

::

  cd haltr
  bundle install
  cd <Redmine root dir>
  rake gems:install

* Apply the database changes

::

  cd <Redmine root dir>
  rake db:migrate:plugins RAILS_ENV='production'

* Clone iso_countries on Haltr's vendor/plugins folder

::

  cd <Redmine root dir>
  cd vendor/plugins/haltr/vendor/plugins
  git clone https://github.com/koke/iso_countries.git

* poppler-utils package and chronic gem are required to receive PDF invoices by mail.
* imagemagick library is required to resize automatically uploaded images (for company logos).
* gem zip is required to download multiple invoices


.. _Redmine's plugin installation instructions: http://www.redmine.org/projects/redmine/wiki/Plugins
