#!/bin/bash

export defn=/opt/final.yaml

function gatherosArch {
    # Get the OS Name
    export os=$(uname -s | awk '{print tolower($0)}')

    # Get the machine arch
    arch=$(uname -m)
    case "$arch" in
        x86)     arch="x86";;
        ia64)    arch="ia64";;
        i?86)    arch="x86";;
        amd64)   arch="amd64";;
        x86_64)  arch="amd64";;
        sparc64) arch="sparc64";;
        arm64)   arch="arm64";;
        aarch64) arch="arm64";;
        * )      arch="amd64";;
    esac
    export arch
}

gatherosArch

curl -L "https://github.com/mikefarah/yq/releases/latest/download/yq_${os}_${arch}" -o /tmp/yq &&\
chmod +x /tmp/yq

/tmp/yq eval-all -o=y -I=0 '. as $item ireduce ({}; . *+ $item)' /tmp/*.yaml > $defn

function initialize {
    export USER=$(/tmp/yq e -o=y -I=0 '.user' $1)
    export WORKDIR=$(/tmp/yq e -o=y -I=0 '.workdir' $1)
    #mkdir -p $WORKDIR

    export BAS_URL=$(/tmp/yq e -o=y -I=0 '.basurl' $1)
    ## Initial Package options
    PACKAGE_MANAGER=$(/tmp/yq e -o=y -I=0 '.packages.manager' $1)

    ## CHROOT Directory gathering to install packages on the directory
    export CHROOT=$(/tmp/yq e -o=y -I=0 '.packages.chroot' $1)
    if [ ! -z "$CHROOT" ]
    then
        mkdir -p $CHROOT
    fi
    ## Package Options to be passed while every install
    readarray Arry < <(/tmp/yq e -o=j -I=0 '.packages.options[]' $1)
    PACKAGE_OPTIONS=$(echo ${Arry[@]//\"/})
    export PACKAGE_DISABLE=$(/tmp/yq e -o=y -I=0 '.packages.disabled' $1)
}
function builder_install {

    ## Execute commands on Builder Image
    readarray BUILDER_CMD_LIST < <(/tmp/yq e -I=0 '.packages.builder.commands[]' $1)
    for u in "${BUILDER_CMD_LIST[@]}"; do
        eval ${u}
    done

    ## Builder Image stage List which is not required for final Image
    readarray Arry < <(/tmp/yq e -o=j -I=0 '.packages.builder.list[]' $1)
    BUILDER_PACKAGE_LIST=$(echo ${Arry[@]//\"/})

    ### Builder Packages Installation
    if [ ! -z "$BUILDER_PACKAGE_LIST" ]
    then
        $PACKAGE_MANAGER install $PACKAGE_OPTIONS $BUILDER_PACKAGE_LIST
        $PACKAGE_MANAGER clean all && rm -rf /var/cache/* /var/log/dnf* /var/log/yum*
    fi
}
function final_img_install {
    if [ -z "$PACKAGE_DISABLE" ]
    then
        return;
    fi
    ## Release/Final Image Package List
    readarray Arry < <(/tmp/yq e -o=j -I=0 '.packages.list[]' $1)
    RELEASE_PACKAGE_LIST=$(echo ${Arry[@]//\"/})

    ## Installation of Packages for the final Base Image
    if [ ! -z "$RELEASE_PACKAGE_LIST" ]
    then
        if [ ! -z "$CHROOT" ]
        then
            $PACKAGE_MANAGER install --installroot $CHROOT $PACKAGE_OPTIONS $BASE_PACKAGE_OPTIONS $RELEASE_PACKAGE_LIST
        else
            $PACKAGE_MANAGER install $PACKAGE_OPTIONS $BASE_PACKAGE_OPTIONS $RELEASE_PACKAGE_LIST
        fi

        $PACKAGE_MANAGER clean all && rm -rf $CHROOT/var/cache/* $CHROOT/var/log/dnf* $CHROOT/var/log/yum.*
    fi
    #sed -i -e '/LANG/c LANG=en_US.UTF8' $CHROOT/etc/locale.conf
}
function base_img_install {
    if [ -z "$PACKAGE_DISABLE" ]
    then
        return;
    fi

    ## Base Image Package Installation Option
    readarray Arry < <(/tmp/yq e -o=j -I=0 '.packages.base.options[]' $1)
    BASE_PACKAGE_OPTIONS=$(echo ${Arry[@]//\"/})

    ## Base Image Package List
    readarray Arry < <(/tmp/yq e -o=j -I=0 '.packages.base.list[]' $1)
    BASE_PACKAGE_LIST=$(echo ${Arry[@]//\"/})

    ## Creation of Base Image

    if [ ! -z "$CHROOT" ]
    then
        $PACKAGE_MANAGER install --installroot $CHROOT $PACKAGE_OPTIONS $BASE_PACKAGE_OPTIONS $BASE_PACKAGE_LIST
        cp /etc/yum.repos.d/*.repo $CHROOT/etc/yum.repos.d/
    else
        $PACKAGE_MANAGER install $PACKAGE_OPTIONS $BASE_PACKAGE_OPTIONS $BASE_PACKAGE_LIST
    fi

    $PACKAGE_MANAGER clean all && rm -rf $CHROOT/var/cache/* $CHROOT/var/log/dnf* $CHROOT/var/log/yum.*

}

function create_users {
    ## Release/Final Product Image Package List
    readarray Arry < <(/tmp/yq e -o=j -I=0 '.users[]' $1)
    if [ ! -z "$CHROOT" ]
    then
        chrt=($CHROOT "/")
    else
        chrt=('/')
    fi
    for c in "${chrt[@]}"; do
    echo "Creating users on $c"
        for u in "${Arry[@]}"; do
            name=$(echo "$u" | /tmp/yq e '.name' -)
            grp=$(echo "$u" | /tmp/yq e '.group' -)
            uid=$(echo "$u" | /tmp/yq e '.uid' -)
            gid=$(echo "$u" | /tmp/yq e '.gid' -)
            home=$(echo "$u" | /tmp/yq e '.home' -)
            descr=$(echo "$u" | /tmp/yq e '.descr' -)

            #Group Creation
            groupadd -g $gid -R $c $grp

            #User Creation
            useradd -R $c -u $uid -m -g $gid -d ${home} -c "$descr" $name

            # Permission Assignment
            chown $uid:0 "$c${home}"
            chown $uid:0 "$c${home}/.."
            chmod 755 "$c${home}"
        done
    done
    ## Create home directory if not exists
    if [ ! -d "$CHROOT" ]
    then
        mkdir -p $WORKDIR
    fi

}

function cmd_exec {
    ## Release/Final Product Image Package List
    readarray CMD_LIST < <(/tmp/yq e -I=0 '.commands[]' $1)
    for u in "${CMD_LIST[@]}"; do
        source ${u}
    done
}

function install_cron {
    ## List of Cron Task to be added
    readarray CMD_LIST < <(/tmp/yq e -I=0 '.crons[]' $1)
    if [[ ${CMD_LIST[@]} ]] && [ -f $CHROOT/usr/sbin/crond ]
    then
        chmod u+s $CHROOT/usr/sbin/crond
        touch $CHROOT/var/spool/cron/$USER
        for u in "${CMD_LIST[@]}"; do
            echo "${u//\"/}" >> $CHROOT/var/spool/cron/$USER
        done
        chown $USER:0 $CHROOT/var/spool/cron/$USER
        chown $USER:0 $CHROOT/etc/environment
    fi
}
function install_binaries {

    if [ -d "/tmp/bin" ] && [ -n "$(ls -A /tmp/bin)" ]; then
        cd /tmp/bin/
        mkdir -p $WORKDIR/bin
        for FILE in *; do
            mkdir -p $WORKDIR/bin
            install -o $USER -g 0 -m 750  /tmp/bin/$FILE $WORKDIR/bin/
        done
    fi
}
function configure_endpoint {
    ENTRYPOINT=$(/tmp/yq e -o=y -I=0 '.entrypoint' $1)

    if [ ! -z "$ENTRYPOINT" ] && [ -f "/tmp/$ENTRYPOINT" ]
    then
        install -o $USER -g 0 -m 550 /tmp/$ENTRYPOINT $WORKDIR
    fi
}
function cleanup_files {
    ## List of Files/Folder to cleanup before copying to release image
    readarray CMD_LIST < <(/tmp/yq e -o=j -I=0 '.cleanup_files[]' $1)
    for u in "${CMD_LIST[@]}"; do
        echo "Deleting ... ${u//$'\n'/}"
        rm -rf ${u//$'\n'/}
    done
}

initialize $defn
builder_install $defn
base_img_install $defn
final_img_install $defn
create_users $defn
cmd_exec $defn
install_cron $defn
install_binaries $defn
configure_endpoint $defn
cleanup_files $defn
rm -rf $defn
rm -rf /usr/bin/yq