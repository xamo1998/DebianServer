
# Servidor Startup - PIXIE

## Tabla de contenidos
1. [Introducción práctica](#introducción-práctica)
2. [Descripción básica del Sistema](#descripción-básica-del-sistema)
    1. [Configuración inicial del sistema](#configuración-inicial-del-sistema)
    2. [Grupos de trabajo](#grupos-de-trabajo)
    3. [Reporte del login del administrador](#reporte-del-login-del-administrador)
    4. [Copias de seguridad](#copias-de-seguridad)
    5. [Copias de seguridad remotas](#copias-de-seguridad-remotas)
    6. [Tripwire](#tripwire)
    7. [Ficheros CRON](#ficheros-cron)
    8. [Particiones y cuotas](#particiones-y-cuotas)
        1. [Sistema de ficheros /mnt/home](#sistema-de-ficheros-mnthome)
        2. [Aplicar cuotas](#aplicar-cuotas)
    11. [Configurar CGI](#configurar-cgi)
    12. [Ficheros log](#ficheros-log)
3. [Descripción básica de los servidores](#descripción-básica-de-los-servidores)
    1. [SSH](#ssh)
    2. [Apache2](#apache2)
        1. [Introducción](#introducción)
        2. [Instalación Apache2](#instalación-apache2)
        3. [Habilitar fichero .htaccess](#habilitar-fichero-.htaccess)
        4. [Mover HTML](#mover-html)
        5. [Protección anti-ataques DoS](#protección-anti-ataques-dos)
        6. [Página segura HTTPS con SSL-RSA](#página-segura-https-con-ssl-rsa)
        7. [AWStats](#awstats)
    3. [MariaDB](#mariadb)
    4. [Creación de Blogs](#creación-de-blogs)
    5. [Cacti](#cacti)
    6. [Servidor de correo electrónico (Roundcube)](#servidor-de-correo-electrónico-roundcube)
    14. [Servidor FTP](#servidor-ftp)
4. [Explicación scripts CGI](#explicación-scripts-cgi)
5. [Problemas encontrados](#problemas-encontrados)
6. [Posibles mejoras](#posibles-mejoras)
7. [Conclusiones](#conclusiones)
8. [Referencias](#referencias)

## Introducción práctica
La siguiente práctica consistirá en hacer un servidor web para una pequeña startup, como se indica en el enunciado que podremos encontrar en Studium. Nuestro enfoque ha sido hacia una tienda de E-commerce y en concreto de venta de ropa.

Cabe destacar que la plantilla html la hemos descargado ya que era gratuita y la hemos modificado con nuestras necesidades.

Veamos algunas imágenes del sitio web que hemos creado:

![img01](assets/img01.png?raw=true "img01")

![img02](assets/img02.png?raw=true "img02")

![img03](assets/img03.png?raw=true "img03")

![img04](assets/img04.png?raw=true "img04")

## Descripción básica del Sistema

Lo primero que tenemos que conocer, antes de entrar en detalle de la descripción básica del sistema, es conocer el sistema operativo donde vamos a realizar la práctica.
Para la realización de la práctica se han usado tanto las distribuciones debian instaladas en el laboratorio de informática como Ubuntu para poder utilizarlo desde casa. En nuestro caso hemos usado *Ubuntu 18.04.2*.

### Configuración inicial del sistema

Primero debemos actualizar el sistema e instalar algunos módulos que necesitaremos más adelante. Para actualizar el sistema:

```
apt-get update
apt-get upgrade
```
Después debemos instalar el siguiente paquete:
```
apt-get install build-essential
```

### Grupos de trabajo

Lo primero que realizaremos para la configuración del sistema es la creación de los dos grupos de usuarios requeridos (CLIENTES y TECNICOS)
Para añadirlos lo hacemos con la siguiente orden:
```
groupadd CLIENTES
groupadd TECNICOS
```
Si queremos ver el id de los usuarios que se encuentran en nuestro sistema podemos usar la siguiente orden:
```
cat /etc/group | awk -F ":" '{ print $1,$3 }'
```
La salida que obtenemos es la siguiente:

![img05](assets/img05.png?raw=true "img05")

También debemos crear una carpeta para el grupo de técnicos en la cual solo puedan acceder ellos por lo que la crearemos en el directorio */mnt/home/manuales*. Cabe destacar que */mnt/home* en el momento de esta explicación no está creado ya que será la partición donde guardaremos los usuarios, sin embargo, en [esta]() sección podemos ver como instalarla.
Para la creación de esta carpeta realizamos los siguientes comandos:

```
mkdir /mnt/home/manuales
chown root:1004 /mnt/home/manuales
```
Donde pone 1004 se debe poner el número que nos devuelve el comando que hemos explicado anteriormente. El comando *chown* sirve para especificar el o los propietarios de un archivo o carpeta.
### Reporte del login del administrador
Para la realización de este apartado haremos uso de la carpeta */etc/profile.d/* esta carpeta contiene con una serie de scripts que se ejecutan al iniciar sesión. Encontramos un problema ya que al guardar en esta carpeta nuestro código de perl para enviar un correo al administrador, no se ejecutaba el programa por lo que creamos un fichero *.sh* que ejecutara el *.pl*. El script *.sh* es el siguiente:

```perl
#!/usr/bin/bash
`perl /etc/profile.d/report_root_login.pl`;
```
El script *.pl* es el siguiente:
```perl
#!/usr/bin/perl
use strict;
use warnings;

use Mail::Sender;
use Email::Send::SMTP::Gmail;


my $destination='xamo1998@gmail.com';
my ($mail,$error)=Email::Send::SMTP::Gmail->new( -smtp=>'smtp.gmail.com',
                                                 -login=>'xamo1998@gmail.com',
                                                 -pass=>'XXXXXXXXXXXXXXXXXXX',
                                                 -layer=>'ssl');
print "Session error: $error" unless ($mail!=1);
$mail->send(-to=>$destination,-subject=>'Admin Login', -body=>'The admin just loged in the system! =) ', -attachments=>'');
$mail->bye;
```
Para el correcto funcionamiento del código anterior hemos tenido que instalar a través de CPAN los módulos *Mail::Sender* y *Email::Send::SMTP::Gmail*, para ello tan solo ejecutamos el comando cpan y una vez dentro *install Mail::Sender* y *Email::Send::SMTP::Gmail*.

### Copias de seguridad
En este apartado vamos a explicar el método que hemos usado para la realización de las copias de seguridad.
Dicho esto, vamos a explicar como lo hemos hecho, hemos utilizado rsync que es una aplicación libre para sistemas de tipo Unix y Microsoft Windows que ofrece transmisión eficiente de datos incrementales, que opera también con datos comprimidos y cifrados.
Primero mostraremos el fichero que realiza las copias de seguridad:
```perl
#!/usr/bin/perl
use warnings;
use strict;

system('rsync -av /mnt /var/backups/backup_mnt.rsync');
system('rsync -av /etc /var/backups/backup_etc.rsync');
system('rsync -av /home /var/backups/backup_home.rsync');
system('rsync -av /usr/local/sbin /var/backups/backup_usr.rsync');
my $perm=0644;
chmod($perm, "/var/backups/backup_mnt.rsync");
chmod($perm, "/var/backups/backup_etc.rsync");
chmod($perm, "/var/backups/backup_home.rsync");
chmod($perm, "/var/backups/backup_usr.rsync");
```

Este archivo se encuentra en la carpeta _/usr/local/sbin/backups.pl_ y como vemos nos genera una copia de seguridad para las carpetas que nos interesa conservar si se pierden:
-	**/mnt/home**:  Aquí se encuentran todos los usuarios que se registran en el sistema.
-	**/etc**: Archivos de configuración para el correcto funcionamiento del servidor
-	**/home**: Para guardar las carpetas del usuario principal y de otros tipos de usuarios que se encuentren en este directorio.
-	**/usr/local/sbin**: En esta carpeta guardamos los scripts que se ejecutan con el cron.

Si ejecutamos el archivo podemos ver las copias de seguridad que nos ha generado:

![img06](assets/img06.png?raw=true "img06")

Si vemos el tamaño de estos ficheros con el comando *du* vemos que el más grande es el home ya que tenemos muchas cosas descargadas:

![img07](assets/img07.png?raw=true "img07")

Tras haber hecho esto, vamos a ver como hemos hecho las copias remotas, las cuales enviamos por Dropbox utilizando el siguiente código.
### Copias de seguridad remotas

Hemos escrito un script el cual permite al administrador mandar sus copias de seguridad a la nube, en este caso a Dropbox, para ello, debemos implementar una serie de cosas:
Primero entramos en Dropbox developers, iniciamos sesión y creamos una aplicación:

![img08](assets/img08.png?raw=true "img08")

Después nos pide 3 datos:

![img09](assets/img09.png?raw=true "img09")

El código es el siguiente:
```perl
use WebService::Dropbox;

my $dropbox = WebService::Dropbox->new({
    key => '1mrpx4in244hy2h', # App Key
    secret => 'cm20j76v7xfwnyf' # App Secret
});
# Authorization
if ($access_token) {
    $dropbox->access_token($access_token);
} else {
    my $url = $dropbox->authorize;

    print "Please Access URL and press Enter: $url\n";
    print "Please Input Code: ";

    chomp( my $code = <STDIN> );

    unless ($dropbox->token($code)) {
        die $dropbox->error;
    }

	    print "Successfully authorized.\nYour AccessToken: ", $dropbox->access_token, "\n";
}

my $info = $dropbox->get_current_account or die $dropbox->error;
 my $to_compress="/var/backups/backup_mnt.rsync /var/backups/backup_usr.rsync /var/backups/backup_etc.rsync";
 my $compressed="/var/backups/backup_mnt.zip";
system("zip -r $compressed $to_compress");
# upload
# https://www.dropbox.com/developers/documentation/http/documentation#files-upload
my $fh_upload = IO::File->new("/var/backups/backup_mnt.zip");
$dropbox->upload('/make_test_folder/backup.zip', $fh_upload) or die $dropbox->error;
$fh_upload->close;
unlink $compressed;
```
Veamos un ejemplo, todos los *.rsync* están dentro de */var/backups/* por lo que los comprimiremos en un *.zip* y los enviaremos a la cuenta del administrador.
Al ejecutar nos proporciona un link el cual al ponerlo en el navegador nos da un código para poder subir los archivos:

![img10](assets/img10.png?raw=true "img10")

Si introducimos el link en el navegador nos aparecerá una ventana como esta:

![img11](assets/img11.png?raw=true "img11")

Le damos a continuar y nos mostrará un código de verificación el cual debemos copiar en el script que estábamos ejecutando anteriormente:

![img12](assets/img12.png?raw=true "img12")

Al copiar el código y dar enter se creará el fichero zip y al acabar se enviará a Dropbox como podemos ver en las siguientes imágenes:

![img13](assets/img13.png?raw=true "img13")

![img14](assets/img14.png?raw=true "img14")

![img15](assets/img15.png?raw=true "img15")

Otra opción para las copias de seguridad remotas es mediante rsync y ssh, dejamos el código para realizarlo con este método:
```perl
#!/usr/bin/perl

use warnings;
use strict;

system('rsync -av /mnt/home backup_mnt.rysnc');
system('rsync -av /etc backup_etc.rysnc');
system('rsync -av /var backup_var.rysnc');
system('rsync -av /usr/local/sbin backup_usr.rysnc');

system('rsync -avz -P -e ssh /mnt/home/backup_mnt.rysnc root@172.20.1.58:/home/backups');
system('rsync -avz -P -e ssh /etc/backup_etc.rysnc root@172.20.1.58:/home/backups');
system('rsync -avz -P -e ssh /var/backup_var.rysnc root@172.20.1.58:/home/backups');
system('rsync -avz -P -e ssh /usr/local/sbin/backup_usr.rysnc root@172.20.1.58:/home/backups');
```
### Tripwire

Para la monitorización local hemos usado Tripwire el cual, al ejecutarlo nos proporciona una gran cantidad de información muy útil para el administrador. Para instalar tripwire debemos realizar los siguientes pasos:
Instalamos tripwire con la siguiente orden:
```
apt-get install tripwire
```
lo configuramos como sitio de internet:

![img 16](assets/img16.png?raw=true "img16")

Configuramos nuestro dominio:

![img 17](assets/img17.png?raw=true "img17")

Damos a Si hasta que nos pida una contraseña y la instalación finalizará.
Una vez instalado, es necesario inicializar el sistema de la base de datos con el siguiente comando:
```
tripwire --init
```
Antes de editar la configuración de tripwire, debemos realizar el siguiente comando:
```
sh -c "tripwire --check | grep Filename > no-directory.txt"
```
En este paso debemos ir al directorio de configuración de tripwire y editar el archivo de configuración *rwpool.txt*

![img 18](assets/img18.png?raw=true "img18")

Comentamos la línea del *rc.boot*.

![img 19](assets/img19.png?raw=true "img19")

Comentamos las dos líneas dadas en la imagen.

![img 20](assets/img20.png?raw=true "img20")

Comentamos todas las líneas de la imagen.

![img 21](assets/img21.png?raw=true "img21")

Comentamos y escribimos todas las líneas que vemos en la imagen.

Una vez hechos estos pasos, ejecutamos el siguiente comando:
```
tripwire –update-policy –secure-mode low /etc/tripwire/twpol.txt
```
Para regenerar el archivo de configuración de tripwire ejecutaremos las siguiente línea:
```
twadmin -m P /etc/tripwire/twpol.txt
```
Una vez hayamos hecho todo lo anterior tripwire estará funcionando correctamente.

Para ello hemos realizado el siguiente script que se ejecutará cada día por la noche:
```perl
#!/usr/bin/perl
use strict;
use warnings;

use Mail::Sender;
use Email::Send::SMTP::Gmail;

system('tripwire --check >datos.txt');
my $destination='xamo1998@gmail.com';
my ($mail,$error)=Email::Send::SMTP::Gmail->new( -smtp=>'smtp.gmail.com',
                                                 -login=>'xamo1998@gmail.com',
                                                 -pass=>'XXXXXXXXXXXXXXXXXXX',
                                                 -layer=>'ssl');
print "Session error: $error" unless ($mail!=1);
$mail->send(-to=>$destination,-subject=>'Security report', -body=>'Here is your daily report!', -attachments=>'/usr/local/sbin/datos.txt');
$mail->bye;
unlink 'datos.txt';
```
Al ejecutar el código si vamos a nuestro correo podremos ver como se ha enviado correctamente:

![img 22](assets/img22.png?raw=true "img22")

### Ficheros CRON

Aquí explicaremos todos los cron que tenemos en el servidor, para añadir un script al cron tenemos varias opciones, una de ellas es mediante el comando *crontab -e*, otra es modificando el archivo */etc/crontab*.

Mostraremos una captura con los scripts que tenemos en el cron y cuál es su funcionamiento:

![img 23](assets/img23.png?raw=true "img23")

- **check_new_user.pl**: Script que se ejecuta cada 1 minuto y busca en la base de datos de usuarios verificados todos los usuarios y uno a uno los borra de esa base de datos y los mete en la base de datos de usuarios finales, también crea el usuario en Linux
- **delete_users.pl**: Busca en la base de datos de users_to_delete y por cada usuario que haya en esa tabla lo elimina de Linux.
- **change_password.pl**: Busca en la base de datos de users_to_change y por cada usuario que haya en esa tabla lo elimina de Linux y vuelve a crearlo con los nuevos datos.
- **security.pl**: Realiza un check de todo el sistema y le manda la salida al correo del administrador.
- **backups.pl**: Realiza las copias de seguridad.
 

### Particiones y cuotas

Los usuarios deben tener asignadas unas cuotas por lo que hemos optado por crear un sistema de fichero donde guardar los */home* de los usuarios y aplicar ahí las cuotas. Para ello debemos realizar los siguientes pasos.
#### Sistema de ficheros /mnt/home

Primero debemos crear un sistema de ficheros en una carpeta, por ejemplo */home/user/SistemaFich*, para hacer esto realizamos la siguiente orden:
```
dd if=/dev/zero of=/home/hector/SistemaFich count=10240 bs=10240
```
Esta orden nos creara un archivo de aproximadamente 100 Mb lleno de ceros. El siguiente paso es dar formato a este archivo, en nuestro caso hemos elegido ext4 por lo que la orden sería la siguiente:
```
mkfs.ext4 /home/hector/SistemaFich
```
El siguiente paso es montar el sistema de ficheros en el directorio que deseemos, en nuestro caso */mnt/home* por lo que las órdenes a utilizar serían:
```
mkdir /mnt/home
mount -o loop /home/hector/SistemaFich /mnt/home
```
Añadimos una línea al fichero */etc/fstab* el cual se encarga de cargar las particiones del sistema cuando se arranca, para ello escribimos la siguiente línea, con cuidado ya que cada campo se debe separar con un tabulador:
```
/home/hector/SistemaFich /mnt/home ext4 defaults,usrquota 0 0
```
Una vez hecho esto realizamos la siguiente orden:
```
mount -a
```
La partición estará configurada correctamente, si queremos usarla debemos reiniciar el sistema con la orden *reboot*.

#### Aplicar cuotas

Para aplicar las cuotas al sistema de ficheros debemos seguir los siguientes pasos, primero escribimos la siguiente línea:
```
mount -o remount /mnt/home
```
Una vez hecho esto realizamos las siguientes ordenes:
```
quotacheck -cugm mnt/home
quotaon -ugv /mnt/home/
```
Con esto ya tendríamos las cuotas activadas en */mnt/home* para poder ver un resumen de las quotas en ese directorio escribimos la siguiente orden:
```
repquota /mnt/home
```
Obtenemos una salida como esta:

![img 24](assets/img24.png?raw=true "img24")

Para que cada usuario tenga una cuota en concreto lo veremos más adelante en este informe, en concreto en [esta]() sección:
 

### Configurar CGI

Para la comunicación entre el servidor y las páginas web hemos usado CGI, en este apartado vamos a ver como configurarlo para la correcta ejecución de los ficheros .pl.
NOTA: Este paso se debe realizar **después** de la [instalación de apache]()  pero por motivos de presentación en esta memoria lo haremos antes.
Primero debemos activar cgi, para ello realizamos los siguientes comandos:
```apache
a2dismod mpm_event
a2enmod mpm_prefork
a2enmod cgi
```
Después reiniciamos apache con la siguiente orden:
```
systemctl restart apache2
```
Ahora debemos configurar el fichero */etc/apache2/conf-available/cgi-enabled* y copiar lo siguiente:
```
<Directory "/var/www/html/cgi-enabled">
           Options +ExecCGI
           AddHandler cgi-script .cgi .pl .py
</Directory>
```
Después activamos la configuración y reiniciamos apache con las siguientes instrucciones:
```
sudo a2enconf cgi-enabled
sudo service apache2 restart
```
Una vez hecho esto podremos usar ficheros perl para la ejecución de tareas junto con apache.

### Ficheros log
En nuestra práctica utilizamos un fichero log que almacena la hora y el tipo de acceso cada vez que un usuario intenta hacer login en nuestro servidor.
No hemos utilizado ningún tipo de comando ya que desde perl nos ha parecido más fácil abrir un fichero y volcar los datos añadiéndolos al final.

## Descripción básica de los servidores

En este apartado veremos cómo hemos instalado y configurado todos los servidores que usamos en nuestro servidor.
### SSH
Primero debemos instalar SSH, para ello escribimos:
```
apt-get install ssh
```
Después debemos cambiar la configuración del ssh que se encuentra en */etc/ssh/sshd_config*, debemos escribir las siguientes líneas:
```
Port 1060
Protocol 2
LoginGraceTime 2m
PermitRootLogin no
MaxStartups 5
```
Una vez configurado ssh tan solo tenemos que reiniciar el servicio de la siguiente manera:
```
systemctl restart ssh
```
 

### Apache2
En este apartado veremos cómo instalar y configurar Apache.
#### Introducción
El servidor HTTP Apache es un servidor web HTTP de código abierto, para plataformas Unix (BSD, GNU/Linux, etc.), Microsoft Windows, Macintosh y otras. Es una de las herramientas más usadas para la gestión de servidores que requieren HTTP.
#### Instalación Apache2
A continuación, procedemos a ver los pasos seguidos en la instalación y configuración de apache. Lo primero de todo antes de instalar nada, siempre es actualizar el sistema:
Una vez actualizado, instalamos el paquete de apache:
```
apt-get install apache2 apache2-doc apache2-utils
```
La salida que obtenemos es la siguiente:

![img 25](assets/img25.png?raw=true "img25")

Podemos destacar que los paquetes para apache tan solo ocupan 30.9 MB.
Si ahora abrimos nuestro navegador y escribimos en la url: *localhost* obtenemos la siguiente página web:

![img 26](assets/img26.png?raw=true "img26")

Como hemos visto en el punto anterior si escribimos localhost en la url del navegador nos devuelve la página web por defecto, también podemos acceder a esta página mediante la ip de nuestro servidor, para obtener la ip nos basta con usar la orden *ip addr* y obtendremos una salida como esta:

![img 27](assets/img27.png?raw=true "img27")

Como vemos, esta orden nos devuelve la ip privada, al igual que con *localhost*, podemos usar la ip. Si queremos acceder a nuestro servidor por un nombre de dominio, por ejemplo, dominio.com debemos modificar el fichero */etc/hosts* para que al intentar resolver el nombre del dominio no sea necesario hacer una petición de DNS.

El archivo, debe quedar así:

![img 28](assets/img28.png?raw=true "img28")

A la izquierda debemos poner la dirección ip local (127.0.0.1) y a la derecha el nombre de dominio que le asociamos a dicha ip.

Por último, para que nuestro dominio este correctamente configurado debemos modificar el fichero: */etc/apache/sites-availabl/000-default.conf*, y escribir lo siguiente:
```
ServerName adsysshop.com:80
ServerAlias www.adsysshop.com
ServerAdmin webmaster@adsysshop.com
DocumentRoot /var/www/html
```
El siguiente paso es editar el fichero de configuración de Apache:
```
pico /etc/apache/apache.conf
```
Insertamos las siguientes líneas de código:
```
<IfModule mpm_prefork_module>
    StartServers 5
    MinSpareServers 5
    MaxSpareServers 10
    MaxClients 100
    MaxRequestsPerChild 0
</IfModule>
```

![img 29](assets/img29.png?raw=true "img29")

El significado de los campos es el siguiente:
-	**StartServers**: Número de procesos que se ejecutan al iniciar Apache.
-	**MinSpareServers**: Mínima cantidad de procesos que se mantienen en espera.
-	**MaxSpareServers**: Cantidad máxima de procesos en espera
-	**MaxClients**: Número máximo de clientes que se pueden ejecutar
-	**MaxRequestsPerChild**: Número de peticiones que atiende cada hilo de ejecución

Por último, tenemos que reiniciar el servicio para actualizar la configuración:
```
systemctl restart apache2
```

#### Habilitar fichero .htaccess
El archivo .htaccess es un archivo de configuración muy importante que se aplica a cada subcarpeta de nuestro servidor. En este archivo podemos hacer cosas como bloquear ciertas páginas, pedir autentificación para cierta página…

Para configurarlo, primero debemos activar el módulo rewrite de la siguiente manera:
```
a2enmod rewrite  
```
Posteriormente debemos crear una sección *Directory* dentro de la sección *VirtualHost* que encontramos en el archivo: */etc/apache/sites-availabl/000-default.conf*, en este archivo introducimos lo siguiente:
```
 <Directory /var/www/html>  
        Options Indexes FollowSymLinks MultiViews  
        AllowOverride All  
        Require all granted  
        Order allow,deny  
        allow from all  
</Directory>  
```
Una vez hemos modificado es archivo tan solo reiniciamos apache y estará funcionando:
```
systemctl restart apache2  
```
#### Mover HTML
Este paso es el más simple ya que si queremos que aparezca nuestra página web cuando la buscamos en el navegador en vez de la página de bienvenida de apache debemos copiar nuestros archivos html, css, js dentro de, en nuestro caso, */var/www/html/*.

Cuando hagamos esto y pongamos la ip del servidor nos debería salir algo como esto:

![img 30](assets/img30.png?raw=true "img30")

#### Protección anti-ataques DoS
Un ataque de denegación de servicio tiene como objetivo inhabilitar el uso de un sistema, una aplicación o una máquina, con el fin de bloquear el servicio para el que está destinado. Este ataque puede afectar, tanto a la fuente que ofrece la información como puede ser una aplicación o el canal de transmisión, como a la red informática.

Debido a esto vamos a instalar un módulo que nos permita protegernos de este tipo de ataques, para ello instalamos el paquete *libapache2-mod-evasive*:
```
apt-get install libapache2-mod-evasive  
```
Creamos una carpeta donde se almacenarán los registros de actividad:
```
mkdir -p /var/log/apache2/evasive  
```
Damos permisos a apache para que pueda escribir en esta carpeta:
```
chown -R www-data:root /var/log/apache2/evasive  
```
A partir de ahora si alguien nos ataca, en la carpeta de registros */var/log/apache2/evasive* se creará un archivo de texto cuyo nombre será la IP del atacante.

Una vez instalado el módulo debemos configurarlo, para ello debemos de editar el archivo */etc/apache2mods-available/mod-evasive.load*

El archivo estará vacío por lo que escribimos lo siguiente:
```
LoadModule evasive20_module /usr/lib/apache2/modules/mod_evasive20.so  
DOSHashTableSize 2048  
DOSPageCount 20  
DOSSiteCount 30  
DOSPageInterval 1.0  
DOSSiteInterval 1.0  
DOSBlockingPeriod 10.0  
DOSLogDir "/var/log/apache2/evasive"  
DOSEmailNotify root@adsysshop.com  
```
Por último, reiniciamos apache para que el archivo de configuración se cargue:
```
systemctl restart apache2  
```

#### Página segura HTTPS con SSL-RSA
Si queremos tener la posibilidad de establecer conexiones cifradas a través de HTTPS, deberemos tener un certificado SSL. SSL (*Secure Socket Layer*) es el protocolo de cifrado más usado en la web y RSA es el algoritmo que cifrará la información que se envía a través de SSL.

En primer lugar, tenemos que activar el módulo SSL de Apache, para ello ejecutamos:
```
a2enmod ssl  
```
Después debemos crear un archivo de configuración para los sitios seguros de nuestro servidor ejecutando el siguiente comando:
```
a2ensite default-ssl  
```
Por último, reiniciamos apache:
```
systemctl restart apache2
```
El siguiente paso es crear las claves RSA, una publica y otra privada con las cuales se podrá establecer una comunicación segura bidireccional entre el servidor y el cliente. Para la creación de estas claves usaremos el comando openssl que viene instalado por defecto en Debian 9.
Creamos una clave de longitud 2048 bits:
```
openssl genrsa -des3 -out server.key 2048  
```
Obtendremos una salida como la siguiente:

![img 31](assets/img31.png?raw=true "img31")

Ahora debemos crear el certificado en base a la clave que acabamos de general. Un certificado es un archivo que acredita al navegador que la conexión proviene del servidor al que estamos contactando y que no hay usurpación de identidad. A través de él se proporciona la información para establecer la conexión segura. Para esto ejecutamos la siguiente orden:
```
openssl req -new -key server.key -out server.csr  
```
Nos pedirá una serie de datos, lo rellenamos y nos debería salir algo como esto:

![img 32](assets/img32.png?raw=true "img32")

Por último, habrá que firmar el certificado para que el cliente tenga la certeza de que realmente ha sido enviado por nuestro servidor y no por un atacante. Para esto ejecutamos la siguiente orden:
```
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt  
```
El parámetro 365 nos dice que la validez del certificado será de 1 año, aunque después de este periodo de tiempo las conexiones seguirán siendo cifradas y seguras.

Una vez ejecutadas las ordenes anterior disponemos de 2 archivos (en el directorio donde hayamos ejecutado estas órdenes) que debemos copiarlos a */etc/ssl/* para que sean reconocidos por Apache. Para esto, ejecutamos las siguientes líneas:
```
cp server.crt /etc/ssl/certs/  
cp server.key /etc/ssl/private/  
```
Editamos el archivo de configuración para sitios seguros *default-ssl.conf* que se encuentra en el directorio */etc/apache2/sites-available*.

En este archivo debemos modificar las siguientes líneas con el contenido que aparece:
```
SSLCertificateFile /etc/ssl/certs/server.crt  
SSLCertificateKeyFile /etc/ssl/private/server.key  
```
Nos quedaría algo como esto:

![img 33](assets/img33.png?raw=true "img33")

Una vez hecho esto reiniciamos apache:
```
systemctl restart apache2
```
Al reiniciar el servicio nos pedirá que introduzcamos la contraseña que usamos para general las claves.

La petición de esta contraseña ocurrirá siempre que reiniciemos Apache por lo que para automatizar esta tarea y que no la pida siempre haremos lo siguiente:
```
cd /etc/ssl/private/  
cp server.key server.key.otr  
openssl rsa -in server.key.otr -out server.key  
```
Una vez todo listo podemos probar el funcionamiento a través de un navegador usando el protocolo HTTPS, para ello escribimos *https://nuestra_ip* , y obtendremos lo siguiente:

![img 34](assets/img34.png?raw=true "img34")

Nos aparece este mensaje debido a que nuestro certificado no se encuentra dentro del certificado raíz del navegador ya que no proviene de una entidad certificadora, sin embargo, esto no compromete la seguridad de la conexión, podemos ver el certificado que ha obtenido el navegador:

![img 35](assets/img35.png?raw=true "img35")

Al añadir la excepción vamos a nuestra página web. Si observamos los detalles del enlace, vemos que, por ejemplo, en Firefox se ha establecido una conexión cifrada:

![img 36](assets/img36.png?raw=true "img36")


#### AWStats
AWStats es un programa que nos permite registrar la actividad de nuestro servidor Apache. Genera estadísticas de visitas que ordena temporalmente y tiene una gran cantidad de información útil para el administrador.

![img 37](assets/img37.png?raw=true "img37")

Para la instalación de AWStats debemos instalar algunos paquetes:
```
apt-get install awstats libnet-ip-perl libgeo-ipfree-perl  
```
Obtendremos una salida como esta:

![img 38](assets/img38.png?raw=true "img38")

Una vez realizado este paso, editaremos el archivo de configuración de AWStat que se encuentra en: */etc/share/doc/awstats/examples/awstats_configure.pl* y cambiaremos las siguientes líneas con el siguiente contenido:
```perl
$AWSTATS_PATH='/usr/share/awstats';  
$AWSTATS_ICON_PATH='/usr/share/awstats/icon';  
$AWSTATS_CSS_PATH='/usr/share/awstats/css';  
$AWSTATS_CLASSES_PATH='/usr/share/awstats/lib';  
$AWSTATS_CGI_PATH='/usr/lib/cgi-bin';  
$AWSTATS_MODEL_CONFIG='/usr/share/doc/awstat/examples/awstats.model.conf';
```
Para que Apache pueda acceder al programa para mostrar las estadísticas, hay que cambiar los permisos de este fichero de la siguiente forma:
```
chown www-data /usr/lib/cgi-bin/awstats.pl  
```
Ahora debemos crear nuestra instancia de AWStats para nuestro dominio, para ello debemos editar/crear el archivo */etc/awstats/awstats.midominio.com.conf*. Dentro de este archivo escribimos lo siguiente:
```perl
LogFile="/var/log/apache2/access_dplinux.log"  
LogFormat=1  
SiteDomain="adsysshop.com"  
DNSLookup=0  
LoadPlugin="tooltips"  
LoadPlugin="geoipfree"  
```
El siguiente paso es modificar los permisos de la carpeta de registros de Apache para que AWStats pueda tener acceso a ella, lo hacemos de la siguiente forma:
```
chmod 755 /var/log/apache2  
```
Ahora configuramos el servicio cron de Linux. Este servicio ejecuta procesos periódicamente. Para añadir este archivo, abrimos el fichero */etc/crontab* y añadimos la siguiente línea al final:
```
*/10 * * * * root /usr/lib/cgi-bin/awstats.pl -config=adsysshop.com -update > /dev/null  
```
Esta línea significa que cada 10 minutos se va a ejecutar el script awstats.pl con el usuario root usando la configuración para *adsysshop.com*.

Por último, vamos a restringir el acceso a estas estadísticas para que solo el administrador tenga permisos para verlas, para ello no s dirigimos al directorio */usr/lib/cgi-bin/* y creamos un archivo .htaccess con el siguiente contenido:
```
<Files "awstats.pl">  
    AuthName "Introducza credenciales"  
    AuthType Basic  
    AuthUserFile /var/www/html/awstats/.htpasswd  
    require valid-user  
</Files>  
```
Con este archivo estamos diciendo que cuando se acceda al archivo awstats.pl desde el navegador, se requerirán credenciales para poder visualizarlo. El siguiente paso es crear una carpeta llamada awstats dentro del directorio */var/www/html*, accedemos al directorio que acabamos de crear y escribimos lo siguiente:
```
htpasswd -c /var/www/html/awstats/.htpasswd adminUser  
```
Nos pedirá la contraseña del usuario que le hayamos indicado.

Una vez hecho esto, editamos el fichero */etc/apache2/sites-available/000-default.conf* y añadimos al final de la sección VirtualHost lo siguiente:
```
Alias /icon/ /usr/share/awstats/icon/  
<Directory /usr/share/awstats/icon>  
    Options None  
    AllowOverride None  
    Require all granted  
    Allow from all  
</Directory>  
ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/  
<Directory "/usr/lib/cgi-bin">  
    AllowOverride All  
    Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch  
    Require all granted  
    Allow from all  
</Directory>  
Alias /awstatsclasses "/usr/share/awstats/lib/"  
Alias /awstats-icon/ "/usr/share/awstats/icon/"  
Alias /awstatscss "/usr/share/doc/awstats/examples/css"  
ScriptAlias /Estadisticas/ /usr/lib/cgi-bin/
```
Nos debe quedar algo como esto:

![img 39](assets/img39.png?raw=true "img39")

Con esto decimos que en algún momento querremos acceder al contenido del directorio */usr/lib/cgi-bin* que es donde se encuentra AWStats, esto se hace a través de un enlace simbólico con la función *ScriptAlias*. Tambien le hemos dicho que al acceder a la carpeta Estadísticas dentro del navegador ejecute el contenido de */usr/lib/cgi-bin*.

Generamos las estadísticas por primera vez con la siguiente línea de código:
```
/usr/lib/cgi-bin/awstats.pl -config=adminshop.com -update  
```
Habilitamos el módulo CGI si no estaba activado y reiniciamos Apache:
```
a2enmod cgi  
systemctl restart apache2
```
En el caso de encontrar algún problema modificar la siguiente línea del archivo */etc/awstats/awstats.conf*:
```
SiteDomain="tudominio.com"  
```

![img 40](assets/img40.png?raw=true "img40")

Para acceder a las estadísticas nos debemos dirigir a *http://tudominio.com/Estadisticas/awstats.pl*, nos pedirá el usuario y contraseña que configuramos anteriormente y podremos ver una gran cantidad de información, mostraremos aquí algunas para visualizar el correcto funcionamiento de la herramienta:

![img 41](assets/img41.png?raw=true "img41")


![img 42](assets/img42.png?raw=true "img42")


![img 43](assets/img43.png?raw=true "img43")

### MariaDB
En este apartado veremos cómo configurar MariaDB junto con Mysql y phpMyAdmin para guardar la información de los usuarios que se registran en nuestro servidor así como información que usan otros servidores que hemos instalado en nuestro servidor.

El primer paso es instalar mariadb junto con los paquetes necesarios, la orden es:
```
apt-get install mariadb-server mariadb-client   
apt-get install php php-cgi libapache2-mod-php php-common php-pear   
apt-get install default-libmysqlclient-dev
```
La salida que obtenemos es la siguiente:

![img 44](assets/img44.png?raw=true "img44")

Después procedemos a instalar phpmyadmin, para ello utilizaremos la siguiente orden:
```
apt-get install phpmyadmin php-mbstring pgp-gettext
```
Obtenemos la siguiente salida:

![img 45](assets/img45.png?raw=true "img45")

En los pasos de la instalación seleccionamos lo siguiente:

![img 46](assets/img46.png?raw=true "img46")

![img 47](assets/img47.png?raw=true "img47")

En este paso seleccionamos la contraseña que queramos.

Una vez llegado este punto, debemos crear un usuario en mariadb que tenga los privilegios de todas las bases de datos, para ello realizamos lo siguiente:
```sql
mariadb -u root -p  
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'password';  
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;  
FLUSH PRIVILEGES;  
exit;  
```
Por último, para activar phpmyadmin junto con apache debemos crear un enlace simbólico del archivo de configuración de apache de la siguiente manera:
```
ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf  
```
Activamos phpmyadmin y reiniciamos Apache de la siguiente forma:
```
a2enconf phpmyadmin  
systemctl restart apache2  
```
Accedemos a *http://midominio.com/phpmyadmin* e iniciamos sesión con el usuario que hemos creado:

![img 48](assets/img48.png?raw=true "img48")

Al iniciar sesión nos debemos ir a la opción *New* y crear, en nuestro caso, la base se llamará *Users*

![img 49](assets/img49.png?raw=true "img49")

Una vez creada esta base de datos accedemos a ella y dentro al apartado de SQL donde pondremos las sentencias SQL para la creación de las tablas necesarias en nuestro servidor:

![img 50](assets/img50.png?raw=true "img50")

Las sentencias de SQL que usaremos son las siguientes:
```sql
CREATE TABLE unverified_users (  
    id INT(11) NOT NULL AUTO_INCREMENT,  
    username VARCHAR(50) NOT NULL,  
    name VARCHAR(50) NOT NULL,  
    last_name VARCHAR(50) NOT NULL,  
    password VARCHAR(150) NOT NULL,  
    email VARCHAR(50) NOT NULL,  
    ver_code INT(11) NOT NULL,  
    PRIMARY KEY (id)  
    );  

CREATE TABLE verified_users (  
    id INT(11) NOT NULL AUTO_INCREMENT,  
    username VARCHAR(50) NOT NULL,  
    name VARCHAR(50) NOT NULL,  
    last_name VARCHAR(50) NOT NULL,  
    password VARCHAR(150) NOT NULL,  
    email VARCHAR(50) NOT NULL,  
    PRIMARY KEY (id)  
    );  
CREATE TABLE final_users (  
    id INT(11) NOT NULL AUTO_INCREMENT,  
    username VARCHAR(50) NOT NULL,  
    name VARCHAR(50) NOT NULL,  
    last_name VARCHAR(50) NOT NULL,  
    password VARCHAR(150) NOT NULL,  
    email VARCHAR(50) NOT NULL,  
    PRIMARY KEY (id)  
    );  
CREATE TABLE users_to_delete (  
    username VARCHAR(50) NOT NULL  
    );  
CREATE TABLE users_to_change (  
    username VARCHAR(50) NOT NULL  
    );  
```
Esto nos creara 5 tablas:
1.	**Unverified_users**: Tabla en la cual guardaremos los usuarios que se han registrado en el sistema, pero no han verificado su correo electrónico/usuario. El campo que destacar es ver_code el cual utilizamos para asignar al usuario un código de verificación.
2.	**Verified_users**: Tabla en la cual guardaremos los usuarios que han confirmado su correo electrónico/usuario pero que aún no se ha procesado la creación del usuario en el servidor.
3.	**Final_users**: Tabla en la cual guardaremos los usuarios finales que tienen acceso al servidor y a su página principal.
4.	**Users_to_delete**: Tabla en la cual guardaremos el nombre de los usuarios que han solicitado que se borre su usuario.
5.	**Users_to_change**: Tabla en la cual guardaremos el nombre de los usuarios que han solicitado cambiar su contraseña.
 

### Creación de Blogs
Para la creación de blogs hemos usado Wordpress ya que es la opción más popular y dispone de una gran comunidad detrás que crea y mantiene plugins que añaden interesantes funciones a este gestor de contenidos, para instalarlo debemos seguir los siguientes pasos:

Primero lo descargamos desde su página principal con la siguiente orden:
```
Wget https://es.wordpress.org/wordpress-5.2.1-es_ES.tar.gz  
```
Lo descomprimimos con la siguiente orden:
```
Tar xzvf wordpress-5.2.1-es_ES.tar.gz  
```
Lo movemos a la carpeta de apache con la siguiente orden:
```
Mv /home/usuario/wordpress /var/www/html/  
```
Cambiamos el propietario de la carpeta para que Apache pueda acceder y manipular el contenido cuando lo necesite:
```
chown -R www-data:www-data /var/www/html/wordpress/  
```
Al ir a la dirección *http::tudominio.com/wordpress/* nos saldrá lo siguiente:

![img 51](assets/img51.png?raw=true "img51")

Antes de continuar debemos crear una base de datos, para ello escribimos:
```sql
mariadb -u admin -p  
create database wordpress;  
exit;
```

![img 52](assets/img52.png?raw=true "img52")

Introducimos el nombre de la base de datos que acabamos de crear y el nombre de usuario y contraseña del usuario con todos los permisos.

### Cacti
Cacti es un visualizador de la actividad de nuestro servidor a través de una interfaz web que permite ver las estadísticas de uso en distintos periodos.

Para instalarlo tan solo debemos realizar la siguiente orden:
```
apt-get install cacti  
```
Una vez instalado si vamos a la dirección *http::tudominio.com/cacti/* podremos iniciar sesión y monitorizar nuestro servidor.

![img 53](assets/img53.png?raw=true "img53")


### 3.13. Servidor de correo electrónico (Roundcube)
Para instalar Roundcube el primer paso que debemos seguir es escribir lo siguiente:
```
apt-get install php5 php5-mysql postfix apache2 dovecot-imapd dovecot-pop3d mysql-server mysql-client roundcube  
```
Una vez instalados todos los paquetes, roundcube nos pedirá un usuario y contraseña, estos datos son los del usuario administrador en nuestra base de datos.

Editamos el fichero de configuración que se encuentra en */etc/apache2/conf-available/roundcube.conf* y descomentamos la línea de *Alias*:

![img 54](assets/img54.png?raw=true "img54")

Después reiniciamos el servicio de apache con la orden:
```
systemctl restart apache2  
```
Debemos crear un enlace simbólico con una nueva ruta para roundcube dentro de webmail:
```
Ln -s /var/lib/roundcube/ /var/www/html/webmail
```
Una vez hecho esto si entramos en la dirección *http://midominio.com/roundcube* podremos iniciar sesión tanto poniendo en la parte de servidor localhost como la ip del servidor.

![img 55](assets/img55.png?raw=true "img55")

### Servidor FTP
Vamos a implementar 2 métodos, uno para la bajada de archivos mediante *proftpd* y otro mediante *filezilla*.

Vamos a ver como instalar el primero de ellos:

Lo primero que debemos hacer es instalar *proftpd* y lo hacemos con la siguiente orden:
```
apt-get install proftpd  
```
Configuramos el archivo *proftpd.conf* que se encuentra en */etc/proftpd* y añadir las siguientes líneas al final del archivo:
```
<Global>  
        RootLogin off  
        RequireValidShell off  
</Global>  
```
Nos debe quedar algo así:

![img 56](assets/img56.png?raw=true "img56")

Si accedemos al servidor de la siguiente forma: *ftp:/localhost/* nos pedirá un usuario y contraseña para poder descargar los archivos de ese usuario.

![img 57](assets/img57.png?raw=true "img57")


![img 58](assets/img58.png?raw=true "img58")

## Explicación scripts CGI
En este apartado vamos a explicar el funcionamiento de todos los scripts que tenemos instalados en nuestro servidor. No entraremos en detalles de programación ya que de lo contrario esta memoria se haría extremadamente extensa por lo que explicaremos el funcionamiento de cada uno y destacaremos aspectos importantes.

Todos estos scripts se han introducido en la carpeta */var/www/html/cgi-enabled*

-	**Change_password.pl**: Este script se ejecuta cuando el usuario, escribe una nueva contraseña. Este script se encarga de validar que el usuario tenga la contraseña que realmente dice, en el caso de que sea su contraseña, le borra de la base de datos de usuarios finales, lo modifica y lo vuelve a meter en la base de datos con su contraseña actualizada.
Tambien se encarga de meter el nombre del usuario en la base de datos de users_to_change para que el script que se ejecuta cada minuto sepa que alguien quiera cambiar su contraseña, este script es el encargado de actualizar el usuario en Linux
-	**Confirm.pl**: Este script se encarga de verificar a los usuarios que hacen click en el link de verificación que se le manda por correo. Obtiene los parámetros de la URL y busca al usuario en la base de datos de usuarios no verificados, si ese usuario se encuentra en allí y su código coincide lo borra de la tabla de no verificados y lo introduce en la de verificados.
-	**Delete_user.pl**: Este script se encarga de que cuando un usuario quiere borrar su cuenta, lo elimina de la base de datos, cierra su sesión e introduce su nombre de usuario en la tabla de usuarios a borrar para que el script que se ejecuta cada minuto sepa que tiene que eliminarlo.
-	**Logout.pl**: Este script se ejecuta cuando un usuario quiere cerrar sesión.
-	**Forgot_password.pl**: Cuando un usuario olvida su contraseña se le envía una nueva por correo. Primero se genera una contraseña aleatoria y se le envía al usuario.
-	**Login.pl**: Este script recoge los datos del formulario y busca al usuario en la base de datos de usuarios finales, en caso de encontrarle, crea una sesión y lo redirige a su perfil, en el caso de no encontrarle le busca en las distintas tablas para mostrarle un mensaje informativo de por qué el acceso es erróneo (por ejemplo que el usuario este siendo verificado)
-	**Private.pl**: Se asegura de que hay una sesión activa, en el caso de que la haya le redirecciona a su perfil y en el caso de que no la haya le redirecciona a login.
-	**Register.pl**: Script que recoge los datos del usuario introducidos en el formulario, crea un usuario con una contraseña aleatoria y lo introduce en la base de datos de usuarios sin verificar. También le manda un correo al usuario con el link de confirmación y su contraseña.
 

### Problemas encontrados
Hemos encontrado un gran número de problemas en prácticamente todos los aspectos de la práctica que hacen que sea muy difícil explicarlos todos.

La gran mayoría acababan siendo problemas de:
-	Permisos
-	Falta de paquetes
-	Falta de configuración
-	Incompatibilidades

La gran mayoría hemos logrado solucionarlos pero hay 2 problemas que no hemos podido solventar y son los siguientes:
-	**Tripwire**: Al instalar tripwire en un servidor este recoge la ip en los archivos de su configuración por lo que, en nuestro caso al cambiar el servidor de ordenador (Cosa que no es nada habitual en la vida real) tripwire deja de funcionar y hay que solucionarlo a mano reiniciando una configuración
-	**Wordpress**: Ocurre lo mismo que con Tripwire pero son una gran cantidad de archivos para renombrar por lo que se optara por la instalación el día de la defensa para poder observar sus funcionalidades.
 

### Posibles mejoras
Hemos implementado en el servidor una gran número de funcionalidades pero aun nos han faltado algunas que si hubiéramos tenido más tiempo las hubiéramos implementado, estas mejoras son:
-	Implementar un servidor DNS para poder resolver el nombre de dominio en la red de área local o incluso conseguir una ip publica de algún proveedor para poder hacer referencia al servidor desde fuera o dentro del área local.
-	Mejorar la interfaz del perfil del usuario.
-	Implementar el chat empresarial.
-	Implementar OwnCloud.
-	Usar otro tipo de comunicación entre el servidor y los ficheros de código.
-	Enviar mail al usuario cuando exceda el limite soft.

### Conclusiones
Esta es una de las practicas más completas y complicadas (en cuanto a quebraderos de cabeza) nos hemos encontrado, al menos a nuestro parecer, pero es una práctica que te hace aprender mucho sobre la administración de sistemas y de cómo configurar nuestros propios servidores.
Nos hubiera gustado algo más de libertad para la elección de lenguajes, o métodos de creación de servidores pero dado que está enfocado a administrar y no a crear un servidor eficiente y simple no ha sido posible.

## Referencias
-	https://ubuntuforums.org/showthread.php?t=2258746
-	https://medium.com/@manivannan_data/python-cgi-example-install-and-simple-example-59e049128406
-	https://hardlimit.com/guia-servidor-en-debian/#__RefHeading__124_1337659763
-	https://stackoverflow.com/questions/23293589/perl-module-install-error-cpan
-	https://gist.github.com/Hikingyo/549698845d166e49eb3d238d03d49236
-	http://www.leonardoborda.com/blog/how-to-add-a-new-partition-to-the-fstab-file/
-	https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/deployment_guide/ch-disk-quotas
-	https://www.golinuxhub.com/2018/08/step-by-step-guide-implement-quota-edquota-grace-period-linux.html
-	https://informaticocurioso.wordpress.com/2016/11/15/instalacion-roundcube/
-	https://websiteforstudents.com/install-apche2-php-phpmyadmin-ubuntu-17-04-17-10/
-	https://stackoverflow.com/questions/23293589/perl-module-install-error-cpan
-	https://stackoverflow.com/questions/17572951/unable-to-find-mysql-config-when-installed-dbdmysql-on-amazon-ec2
-	https://www.perl.com/article/43/2013/10/11/How-to-schedule-Perl-scripts-using-cron/
-	https://www.osi.es/es/actualidad/blog/2018/08/21/que-son-los-ataques-dos-y-ddos
-	https://www-solvetic-com.cdn.ampproject.org/v/s/www.solvetic.com/tutoriales/article/4437-instalar-usar-tripwire-detectar-archivos-modificados-ubuntu-17/?ampmode=1&usqp=mq331AQFCAGgAQA%3D&amp_js_v=0.1#referrer=https%3A%2F%2Fwww.google.com&amp_tf=De%20%251%24s&ampshare=https%3A%2F%2Fwww.solvetic.com%2Ftutoriales%2Farticle%2F4437-instalar-usar-tripwire-detectar-archivos-modificados-ubuntu-17%2F
-	https://hardlimit.com/guia-servidor-en-debian/
