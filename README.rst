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


Sending invoices by email
-------------------------

Haltr is designed for use with an external mailing system, to allow to manipulate invoice file before sending it.
(in Spain we must digitally sign invoices before sending them)

In settings, "*Path of export folders*" is where Haltr leaves invoices, and expects another process scheduled to take them, do whatever transformation is needed, send them and report the status change to Haltr.

To report invoice status changes, Haltr provides a RESTful access to an ``Event`` model, which has a particular name and invoice ID.

for example:

::
  
  Event.new(:invoice_id => 1, :name => "success_sending")

would change the status of the invoice with id 1, from "Sending" to "Sent".

Access to the REST service is restricted by source IP, so that events can only be created from the IP that has been set in "*B2brouter IP*"

Finally, "*B2brouter URL*" is the URL where Haltr retrieves the invoices already signed, so that they can be downloaded.

The call looks like this:

::
  
  "#{b2brouter_url}/b2b_messages/get_legal_invoice?md5=#{md5}"


.. _Redmine's plugin installation instructions: http://www.redmine.org/projects/redmine/wiki/Plugins
