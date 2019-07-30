# Servidor Startup - PIXIE

## Tabla de contenidos
1. [Introducción](#introduccion)
2. [Descripción básica del Sistema](#descripcion-basica-del-sistema)
  1. [Configuración inicial del sistema](#_Toc9623158)
  2. [Grupos de trabajo](#_Toc9623159)
  3. [Reporte del login del administrador](#_Toc9623160)
  4. [Copias de seguridad](#_Toc9623161)
  5. [Copias de seguridad remotas](#_Toc9623162)
  6. [Tripwire](#_Toc9623163)
  7. [Ficheros CRON](#_Toc9623164)
  8. [Particiones y cuotas](#_Toc9623165)
  9. [Sistema de ficheros /mnt/home](#_Toc9623166)
  10. [Aplicar cuotas](#_Toc9623167)
  11. [Configurar CGI](#_Toc9623168)
  12. [Ficheros log](#_Toc9623169)
3. [Descripción básica de los servidores](#_Toc9623170)
  1. [SSH.. 23](#_Toc9623171)
  2. [Apache2](#_Toc9623172)
  3. [Introducción](#_Toc9623173)
  4. [Instalación Apache2](#_Toc9623174)
  5. [Habilitar fichero .htaccess](#_Toc9623175)
  6. [Mover HTML](#_Toc9623176)
  7. [Protección anti-ataques DoS](#_Toc9623177)
  8. [Página segura HTTPS con SSL-RSA](#_Toc9623178)
  9. [AWStats](#_Toc9623179)
  10. [MariaDB](#_Toc9623180)
  11. [Creación de Blogs](#_Toc9623181)
  12. [Cacti](#_Toc9623182)
  13. [Servidor de correo electrónico (Roundcube)](#_Toc9623183)
  14. [Servidor FTP](#_Toc9623184)
4. [Explicación scripts CGI](#_Toc9623185)
  1. [Problemas encontrados](#_Toc9623186)
  2. [Posibles mejoras](#_Toc9623187)
  3. [Conclusiones](#_Toc9623188)
5. [Referencias](#_Toc9623189)

## 1. Introdución
La siguiente práctica consistirá en hacer un servidor web para una pequeña startup, como se indica en el enunciado que podremos encontrar en Studium. Nuestro enfoque ha sido hacia una tienda de E-commerce y en concreto de venta de ropa.

Cabe destacar que la plantilla html la hemos descargado ya que era gratuita y la hemos modificado con nuestras necesidades.

Veamos algunas imágenes del sitio web que hemos creado:

![img01](assets/img01.png?raw=true "img01")

![img02](assets/img02.png?raw=true "img02")

![img03](assets/img03.png?raw=true "img03")

![img04](assets/img04.png?raw=true "img04")

## 2. Descripción básica del Sistema

Lo primero que tenemos que conocer, antes de entrar en detalle de la descripción básica del sistema, es conocer el sistema operativo donde vamos a realizar la práctica.
Para la realización de la práctica se han usado tanto las distribuciones debian instaladas en el laboratorio de informática como Ubuntu para poder utilizarlo desde casa. En nuestro caso hemos usado *Ubuntu 18.04.2*.

### 2.1. Configuración inicial del sistema

Primero debemos actualizar el sistema e instalar algunos módulos que necesitaremos más adelante. Para actualizar el sistema:

```
apt-get update
apt-get upgrade
```
Después debemos instalar el siguiente paquete:
```
apt-get install build-essential  
```

### 2.2. Grupos de trabajo

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
### 2.3. Reporte del login del administrador
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

### 2.4. Copias de seguridad
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
### 2.5. Copias de seguridad remotas

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
### 2.6. Tripwire
### 2.7. Ficheros CRON
### 2.8. Particiones y cuotas
### 2.9. Sistema de ficheros /mnt/home
### 2.10. Aplicar cuotas
### 2.11. Configurar CGI
### 2.12. Ficheros log
