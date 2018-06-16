#
# NAME     maven-install-orbeon-jar.sh
# VERSION  1.22.0
# DATE     2018-06-16
#
# Copyright 2012-2017
#
# This file is part of the Linked Data Theatre.
#
# The Linked Data Theatre is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# The Linked Data Theatre is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.
#

mvn install:install-file -Dfile=../orbeon/WEB-INF/lib/orbeon.jar -DgroupId=orbeon -DartifactId=orbeon -Dversion=4.10.0 -Dpackaging=jar -DgeneratePom=true
