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

* Install Haltr plugin following `Redmine's plugin installation instructions`_

* Install required gems

::
  
  cd <Redmine root dir>
  rake gems:install

* Clone iso_countries on Haltr's vendor/plugins folder

::

  cd <Redmine root dir>
  cd vendor/plugins/haltr/vendor/plugins
  git clone https://github.com/koke/iso_countries.git

* poppler-utils package is required to receive PDF invoices by mail.


.. _Redmine's plugin installation instructions: http://www.redmine.org/projects/redmine/wiki/Plugins
