#!/bin/bash

usage() {
  echo -e "Usage:\n" >&2
  echo "  cardtool tok[enize] number" >&2
  echo "  cardtool detok[enize] number" >&2
  echo "  cardtool generate [ -c count ] range_start [range_end]" >&2
  echo -en "\nFor (de)tokenization you need to create a file" >&2
  echo " ~/.voltage and add:" >&2
  echo -e "\n  tokenizer=<hostname:port>"  >&2
  echo "  password=<individual tokenization password>" >&2
  echo "  rangepassword=<range tokenization password>" >&2
  echo -e "\nGeneration can accept tokenized ranges\n" >&2
  echo -e "Examples:\n" >&2
  echo -e " cardtool tok 411111111111" >&2
  echo -e " cardtool detok 411111PNRSLW" >&2
  echo -e " cardtool generate -c 5 411111111111" >&2
  echo -e " cardtool generate 411111PNRSLW 4111111111110022\n" >&2
  exit 1
}

[[ -r $HOME/.voltage ]] && source $HOME/.voltage

case ${1:-"invalid"} in

      tok|tokenize) disposition=tokenize;;
  detok|detokenize) disposition=detokenize;;
          generate) disposition=generate;;
                         *) usage;exit 1;;
esac
shift

#####################################################################
# Functions
#####################################################################

luhn() {  # Is a card valid ?
  n=1 ; sum=0 ; local cc=$1
  fib=(0 2 4 6 8 1 3 5 7 9)

  while [ -n "$cc" ]; do
    l=${cc%?} ; d=${cc#"$l"} ; cc=$l
    case $n in
      *[24680]) sum=$(( $sum + ${fib["${d:-0}"]} )) ;;
             *) sum=$(( $sum + ${d:-0} )) ;;
    esac
    n=$(( $n + 1 ))
  done

  [[ $sum == *0 ]] && true || false
}

token_action() {

  local action=$1
  local token=$2

  case $action in
      tokenize) method="Protect";;
    detokenize) method="Access";;
  esac

  case ${#token} in
    12) data_type="FormattedDataList"
        password="$rangepassword"
        format="VE-RNG-A1"
        identity="statelessrange-1";;
    16) data_type="FormattedDataList"   # <----what should this be
        password="$password"
        format="VE-PAN-A1"
        identity="stateless-1";;
     *) echo -e "Bad token length - should be 12 or 16 characters long\n" >&2
        exit;;
  esac

  if [[ -z $password ]];then
    echo -e "\nERROR: Did not find valid password for token action\n" >&2
    usage
    exit 1
  fi

  endpoint="${method}${data_type}"

  tokenizer=${tokenizer:-"panto.$(hostname -f | sed -E 's/[a-z0-9]+.//'):48150"}
  if [[ $tokenizer == *48150 ]];then
    fqdn=$(hostname -f)
    curlopts="--cacert /etc/websphere-as_ce-2.1/security/keystores/ca.crt \
              --cert /etc/websphere-as_ce-2.1/security/keystores/$fqdn.crt \
              --key /etc/websphere-as_ce-2.1/security/keystores/$fqdn.key "
  fi

  payload='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:vib="http://voltage.com/vibesimple">
  <soapenv:Header/>
    <soapenv:Body>
      <vib:'"$endpoint"'>
        <dataIn>'"$token"'</dataIn>
         <format>'"$format"'</format>
         <identity>'"$identity"'</identity>
         <authMethod>SharedSecret</authMethod>
         <authInfo>'"$password"'</authInfo>
      </vib:'"$endpoint"'>
    </soapenv:Body>
  </soapenv:Envelope>'

  data=$(curl -k $curlopts -H "SOAPAction:http://voltage.com/vibesimple/$endpoint" \
                       --data "$payload" \
                           -s  https://$tokenizer/vibesimple/services/VibeSimpleSOAP)

  data=$(echo $data | sed -E 's#.*<dataOut xmlns="">([^<]+)</dataOut>.*#\1#')

  if (( ${#data} <= 16 ));then
    echo $data
  else
    echo -e "\nERROR: could not perform token action\n\n$data\n" >&2
    exit 1
  fi

}

if [[ $disposition == *tokenize ]];then
  token_action $disposition "$@"
  exit
fi

if [[ $disposition == "generate" ]];then

  range_s=411111111111
  while getopts "c:" OPT; do
    case $OPT in
      c) gimme="$OPTARG";;
    esac
  done
  shift $((OPTIND - 1))

  [[ -n $1 ]] && range_s=$1
  [[ -n $2 ]] && range_e=$2

  [[ $range_s == ${range_s//[A-Z]/} ]] || range_s=$(token_action detokenize $range_s) || exit 1
  range_e=${range_e:-$range_s}
  [[ $range_e == ${range_e//[A-Z]/} ]] || range_e=$(token_action detokenize $range_e) || exit 1
  range_s=$(printf "%-16s" $range_s)
  range_e=$(printf "%-16s" $range_e)
  range_s=${range_s// /0}
  range_e=${range_e// /9}

  cc=$range_s
  while (( $cc <= $range_e ));do

    if luhn $cc;then
      echo $cc
      let matches+=1
    fi
    (( ${matches:-0} >= ${gimme:-10} )) && exit
    let cc+=1

  done
  exit 0

fi

