#!/bin/sh

fn_printflags()
{
    echo "qentity         $qentity"
    echo "destfile        $destfile"
    echo "srcfile         $srcfile"
    echo "mvnproject      $mvnproject"
    echo "generatesources $generatesources"
    echo "destfolder      $destfolder"
    echo "srcfolder       $srcfolder"
    echo "compileall      $compileall"
    echo "buildcp         $buildcp"
}

fn_compile()
{
    rm -f sources.txt

    # Get the time of last file compiled
    ltime=$(for file in $(find $destfolder -type f); do echo `date -r $file +%s`; done | sort -r | uniq | head -1)

    for file in $(find $srcfolder/java -type f); do
        if [ `date -r $file +%s` -gt $ltime ]; then
            echo "$file" >> sources.txt
        fi
    done | sort -r

    if [ -f "sources.txt" ]; then
        echo "Staring compilation"
        javac -d $destfolder -cp `cat .classpath` @sources.txt
        rm sources.txt
    fi

    if [ ! -f "sources.txt" ]; then
        echo "Everything is update"
    fi
}

fn_notmavenproject()
{
    echo "it's not a Maven project. To be implemented! Stay tuned!"
}


t0=`date +%s`

destfolder=target/classes
srcfolder=src/main

#while true
for arg in "$@"
do
    case $arg in
        -r|--run)
            shift
            classname=`find $destfolder -name "$1.class" | sed -E "s|$destfolder/||" | sed 's/.class$//'`
            shift
            java -cp `cat .classpath` $classname $@
            exit
            ;;
        -a|--all)
            compileall=1
            shift
            ;;
        -q|--qentity)
            qentity=1
            shift
            ;;
        -o|--output)
            shift
            destfile="$1"
            shift
            ;;
        -x)
            debug=1
            shift
            ;;
        -*)
            echo "$1: Unrecognized option"
            exit 1
            ;;
        *)
            srcfile="$1"
            shift
            ;;
    esac
done

if [ -f pom.xml ]; then
    mvnproject=1
fi

if [ ! -z $qentity ] && [ ! -z $mvnproject ]; then
    generatesources=1
fi

if [ ! -d $destfolder ]; then
    compileall=1
    mkdir -p $destfolder
fi

# Check .classpath file
if [ ! -f ".classpath" ]; then
    buildcp=1
elif [ ! -z $mvnproject ]; then
    pomtime=`date -r "pom.xml" +%s`
    cptime=`date -r ".classpath" +%s`
    if [ $pomtime -gt $cptime ]; then
        buildcp=1
    fi
else
    fn_notmavenproject
fi

if [ ! -z $debug ]; then fn_printflags; fi

if [ ! -z $buildcp ]; then
    echo "Creating classpath"
    rm -f .classpath
    if [ ! -z $mvnproject ]; then
        mvn dependency:build-classpath -Dmdep.outputFile=.classpath
    else
        fn_notmavenproject
    fi
    echo ":"$destfolder >> .classpath
fi

# If we need generate sources and compile whole project, to save time, just
# run 'mvn compile'
if [ ! -z $generatesources ] && [ -z $compileall ]; then
    mvn generate-sources
fi

if [ ! -z $compileall ]; then
    echo "Compile whole project"
    if [ ! -z $mvnproject ]; then
        mvn clean compile
    else
        fn_notmavenproject
    fi
else
    fn_compile
fi


t1=`date +%s`
echo Completed in `expr $t1 - $t0` seconds


#for file in $(find src/main/java -type f); do echo `date -r $file +%s`; done | sort -r | uniq | head -1
#for file in $(find src/main/java -type f); do echo `date -r $file +%s` "$file"; done | sort -r

exit 0

javac -d $destfolder -cp `cat .classpath`:"$destfolder" $1 #@sources.txt
#javac -d target/classes -cp `cat .classpath` ./src/main/java/com/ciaosystem/selling/SellingApplication.java
