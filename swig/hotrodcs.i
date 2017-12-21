%module(directors="1") hotrodcs
%inline {
/* Define org::infinispan::query::remote::client needed by RemoteCacheBase. This in place of including all the protobuf stuff */
namespace org { namespace infinispan { namespace query { namespace remote { namespace client {}}}}}
}

%define %cs_callback(TYPE, CSTYPE)
    %typemap(ctype) TYPE, TYPE& "void *"
    %typemap(in) TYPE  %{ $1 = ($1_type)$input; %}
    %typemap(in) TYPE& %{ $1 = ($1_type)&$input; %}
    %typemap(imtype, out="IntPtr") TYPE, TYPE& "CSTYPE"
    %typemap(cstype, out="IntPtr") TYPE, TYPE& "CSTYPE"
    %typemap(csin) TYPE, TYPE& "$csinput"
%enddef

%cs_callback(infinispan::hotrod::FailOverRequestBalancingStrategy::ProducerFn, FailOverRequestBalancingStrategyProducerDelegate)

%{
#define HR_PROTO_EXPORT
#define _WIN64
#include <infinispan/hotrod/BasicMarshaller.h>
#include <infinispan/hotrod/FailOverRequestBalancingStrategy.h>
#include <infinispan/hotrod/ClientEvent.h>
#include <infinispan/hotrod/ClientListener.h>
#include <infinispan/hotrod/Configuration.h>
#include <infinispan/hotrod/ConfigurationBuilder.h>
#include <infinispan/hotrod/ConfigurationChildBuilder.h>
#include <infinispan/hotrod/ConnectionPoolConfiguration.h>
#include <infinispan/hotrod/ConnectionPoolConfigurationBuilder.h>
#include <infinispan/hotrod/SecurityConfigurationBuilder.h>
#include <infinispan/hotrod/SslConfigurationBuilder.h>
#include <infinispan/hotrod/AuthenticationConfigurationBuilder.h>
#include <infinispan/hotrod/AuthenticationConfiguration.h>
#include <infinispan/hotrod/SecurityConfiguration.h>
#include <infinispan/hotrod/Flag.h>
#include <infinispan/hotrod/ImportExport.h>
#include <infinispan/hotrod/Marshaller.h>
#include <infinispan/hotrod/MetadataValue.h>
#include <infinispan/hotrod/RemoteCache.h>
#include <infinispan/hotrod/RemoteCacheBase.h>
#include <infinispan/hotrod/RemoteCacheManager.h>
#include <infinispan/hotrod/ServerConfiguration.h>
#include <infinispan/hotrod/ServerConfigurationBuilder.h>
#include <infinispan/hotrod/SslConfiguration.h>
#include <infinispan/hotrod/NearCacheConfiguration.h>
#include <infinispan/hotrod/TimeUnit.h>
#include <infinispan/hotrod/Version.h>
#include <infinispan/hotrod/VersionedValue.h>
#include <infinispan/hotrod/defs.h>
#include <infinispan/hotrod/exceptions.h>
#include <infinispan/hotrod/InetSocketAddress.h>
#include <infinispan/hotrod/CacheTopologyInfo.h>
#include <swig/DotNetClientListener.h>
%}

/* Change the access modifier for the classes generated by SWIG to 'internal'. */
%pragma(csharp) moduleclassmodifiers="internal class"
%typemap(csclassmodifiers) SWIGTYPE, SWIGTYPE *, SWIGTYPE &, SWIGTYPE [], SWIGTYPE (CLASS::*) "internal class"
%typemap(csclassmodifiers) enum SWIGTYPE "internal enum"

/* Force a common interface between the 32 and 64 bit wrapper code. */
%include "hotrod_arch.i"

%include "exception.i"
%include "hotrod_exception.i"

%include "stdint.i"
%include "std_string.i"
%include "std_pair.i"
%include "std_map.i"
%include "std_vector.i"
%include "std_set.i"

%template (VectorChar) std::vector<char>;
%template (VectorVectorChar) std::vector<std::vector<char> >;
%template (VectorByte) std::vector<unsigned char>;

%include "std_shared_ptr.i"
%shared_ptr(infinispan::hotrod::ByteArray)

%feature("director") AuthenticationStringCallback;
%feature("director") ClientListenerCallback;
%feature("director") FailOverRequestBalancingStrategy;
%feature("director") FailOverRequestBalancingStrategyProducer;
%feature("director") FailOverRequestBalancingStrategyProducerDelegate;


%inline{
class AuthenticationStringCallback {
public:
    AuthenticationStringCallback() { }
    AuthenticationStringCallback(const char* s) : c_string(s) { }
    virtual ~AuthenticationStringCallback() { }
    virtual std::string getString() { return c_string; };
    const char* getCString() { return c_string.data(); };
    std::string c_string;
};

static int getrealm(void* context, int id, const char** result, unsigned int *len) {
    AuthenticationStringCallback * asc = (AuthenticationStringCallback *) context;
    *result=asc->getCString();
    *len = strlen(*result);
    return SASL_OK;
}


static int getsecret(void* /* conn */, void* context, int id, sasl_secret_t **psecret) {
    AuthenticationStringCallback * asc = (AuthenticationStringCallback *) context;
    const std::string& s = asc->getString();
    size_t len = s.length();
    sasl_secret_t * p= (sasl_secret_t*)malloc(sizeof(sasl_secret_t)+len);
    p->len=len;
    strcpy((char*) p->data, s.data());
    *psecret = p;
    return SASL_OK;
}

static int simple(void* context, int id, const char **result, unsigned int *len) {
    AuthenticationStringCallback * asc = (AuthenticationStringCallback *) context;
    *result=asc->getCString();
    if (len)
    {
        *len = strlen(*result);
    }
    return SASL_OK;
}

static int getpath(void *context, const char ** path) {
    AuthenticationStringCallback * asc = (AuthenticationStringCallback *) context;
    *path=asc->getCString();
    if (!path)
        return SASL_BADPARAM;
    return SASL_OK;
}
}


// include order matters.
%include "infinispan/hotrod/ImportExport.h"

%include "infinispan/hotrod/TimeUnit.h"
%include "infinispan/hotrod/defs.h"

%rename(RootException) Exception;
%ignore "HotRodClientException";
%include std_except.i
%include "infinispan/hotrod/exceptions.h"


%include "infinispan/hotrod/Flag.h"
%include "infinispan/hotrod/Version.h"

%include "infinispan/hotrod/VersionedValue.h"
%include "infinispan/hotrod/MetadataValue.h"

%include "infinispan/hotrod/Marshaller.h"
%include "infinispan/hotrod/BasicMarshaller.h"

%include "infinispan/hotrod/InetSocketAddress.h"
%include "infinispan/hotrod/CacheTopologyInfo.h"

%ignore infinispan::hotrod::event::ClientCacheFailoverEvent;
%ignore infinispan::hotrod::event::ClientCacheEntryCustomEvent;
%ignore infinispan::hotrod::event::DotNetClientListener::getFailoverFunction;
%ignore getBalancingStrategy;

%include "infinispan/hotrod/ClientEvent.h"
%include "infinispan/hotrod/ClientListener.h"
%include "infinispan/hotrod/ConnectionPoolConfiguration.h"
%include "infinispan/hotrod/ServerConfiguration.h"
%include "infinispan/hotrod/SslConfiguration.h"
%include "infinispan/hotrod/AuthenticationConfiguration.h"
%include "infinispan/hotrod/SecurityConfiguration.h"
%include "infinispan/hotrod/NearCacheConfiguration.h"
%include "infinispan/hotrod/FailOverRequestBalancingStrategy.h"
%include "infinispan/hotrod/Configuration.h"


%include "infinispan/hotrod/ConfigurationChildBuilder.h"
%include "infinispan/hotrod/ConnectionPoolConfigurationBuilder.h"
%include "infinispan/hotrod/ServerConfigurationBuilder.h"
%include "infinispan/hotrod/SecurityConfigurationBuilder.h"
%include "infinispan/hotrod/SslConfigurationBuilder.h"
%include "infinispan/hotrod/AuthenticationConfigurationBuilder.h"
%include "infinispan/hotrod/ConfigurationBuilder.h"

%include "infinispan/hotrod/RemoteCacheBase.h"
%include "infinispan/hotrod/RemoteCache.h"
%include "infinispan/hotrod/RemoteCacheManager.h"
%include "swig/DotNetClientListener.h" 
%include "arrays_csharp.i"
%apply unsigned char INPUT[] {unsigned char* _bytes}
%apply unsigned char OUTPUT[] {unsigned char* dest_bytes}
%newobject infinispan::hotrod::BasicMarchaller<ByteArray>::unmarshall;

%ignore getAsync;
%ignore putAsync;
%ignore goAsync;
%ignore putAllAsync;
%ignore replaceWithVersionAsync;
%ignore putIfAbsentAsync;
%ignore replaceAsync;
%ignore removeAsync;
%ignore removeWithVersionAsync;
%ignore clearAsync;
%ignore base_query;
%ignore query(const QueryRequest &qr);

%inline{

#include <exception>
#include <string>
#include "infinispan/hotrod/defs.h"

namespace infinispan {
namespace hotrod {

    template<typename T> class ArrayDeleter {
    public:
        void operator()(T *array) const { delete[] array; }
    };

    class ByteArray {
    public:
        ByteArray(): bytes(), size(0) {
            /* Required if ByteArray is used as key in std::map. */
        }

        ByteArray(unsigned char* _bytes, int _size):
            bytes(_bytes, _bytes+_size), size(_size) {
        }

        const unsigned char* getBytes() const {
            return bytes.data();
        }

        void copyBytesTo(unsigned char* dest_bytes) {
            memcpy(dest_bytes, bytes.data(), size);
        }

        int getSize() const {
            return size;
        }

        friend bool operator<(const ByteArray &b1, const ByteArray &b2);
        
    private:
        std::vector<unsigned char> bytes;
        int size;
    };

    bool operator<(const ByteArray &b1, const ByteArray &b2) {
        /* Required if ByteArray is used as key in std::map. */
        int minlength = std::min(b1.getSize(), b2.getSize());
        const unsigned char *bb1 = b1.getBytes(), *bb2 = b2.getBytes();
        for (int i = 0; i < minlength; i++) {
            if (bb1[i] != bb2[i]) {
                return bb1[i] < bb2[i];
            }
        }
        return b1.getSize() < b2.getSize();
    }


    template<> class BasicMarshaller<ByteArray>: public infinispan::hotrod::Marshaller<ByteArray> {
        void marshall(const ByteArray& barray, std::vector<char>& sbuf) {
            if (barray.getSize() == 0) {
                return;
            }
            sbuf.assign(barray.getBytes(), barray.getBytes()+barray.getSize());
        }

        ByteArray* unmarshall(const std::vector<char>& sbuf) {
            int size = sbuf.size();
            unsigned char *bytes = new unsigned char[size];
            memcpy(bytes, sbuf.data(), size);

            return new ByteArray(bytes, size);
        }
    };
}}
}

%inline{
    namespace infinispan {
        namespace hotrod {
            std::vector<std::shared_ptr<ByteArray> > as_vector(std::set<std::shared_ptr<ByteArray> > input) {
                std::vector<std::shared_ptr<ByteArray> > result;
                for (std::set<std::shared_ptr<ByteArray> >::iterator it = input.begin(); it != input.end(); ++it) {
                    result.push_back(*it);
                }
                return result;
            }
        }
    }
 }

%template(RemoteByteArrayCache) infinispan::hotrod::RemoteCache<infinispan::hotrod::ByteArray, infinispan::hotrod::ByteArray>;

%template(ValueMetadataPair) std::pair<std::shared_ptr<infinispan::hotrod::ByteArray>, infinispan::hotrod::MetadataValue>;
%template(ValueVersionPair) std::pair<std::shared_ptr<infinispan::hotrod::ByteArray>, infinispan::hotrod::VersionedValue>;
/* %template(ByteArrayPair) std::pair<infinispan::hotrod::ByteArray, infinispan::hotrod::ByteArray>; */

%template(ByteArrayMap) std::map<std::shared_ptr<infinispan::hotrod::ByteArray>, std::shared_ptr<infinispan::hotrod::ByteArray> >;
%template(ByteArrayMapInput) std::map<infinispan::hotrod::ByteArray, infinispan::hotrod::ByteArray>;
/* %template(ByteArrayPairSet) std::set<ByteArrayPair>; */

%template(StringMap) std::map<std::string, std::string>;
%template(VectorMap) std::map<std::vector<char>, std::vector<char> >;
%template(ByteArrayVector) std::vector<std::shared_ptr<infinispan::hotrod::ByteArray> >;
%template(ServerConfigurationVector) std::vector<infinispan::hotrod::ServerConfiguration>;
%template(ServerConfigurationMap) std::map<std::string,std::vector<infinispan::hotrod::ServerConfiguration> >;
%template(SaslCallbackHandlerMap) std::map<int, AuthenticationStringCallback *>;
%template(InetSocketAddressVector) std::vector<infinispan::hotrod::transport::InetSocketAddress>;
%template(InetSocketAddressSet) std::set<infinispan::hotrod::transport::InetSocketAddress>;
%extend infinispan::hotrod::RemoteCacheManager {
    %template(getByteArrayCache) getCache<infinispan::hotrod::ByteArray, infinispan::hotrod::ByteArray>;
};



%extend infinispan::hotrod::AuthenticationConfigurationBuilder{
    void setupCallback() {}
    void setupCallback(std::map<int, AuthenticationStringCallback *> mAsc)
    {
       int index = 0;
       std::vector<sasl_callback_t> p_callbackHandler(mAsc.size()+1);
       for(auto&& iter: mAsc)
       {
           AuthenticationStringCallback *asc;
           switch (iter.first) 
           {
               case SASL_CB_GETPATH:
                  asc= new AuthenticationStringCallback(iter.second->getString().c_str());
                  p_callbackHandler[index++]= {SASL_CB_GETPATH, (sasl_callback_ft) &getpath, (void*) asc};
                  break;
               case SASL_CB_USER:
                  asc= new AuthenticationStringCallback(iter.second->getString().c_str());
                  p_callbackHandler[index++]= {SASL_CB_USER, (sasl_callback_ft) &simple, (void*) asc};
                  break;
               case SASL_CB_PASS:
                  p_callbackHandler[index++]= {SASL_CB_PASS, (sasl_callback_ft) &getsecret, (void*) iter.second};
                  break;
               case SASL_CB_GETREALM:
                  asc= new AuthenticationStringCallback(iter.second->getString().c_str());
                  p_callbackHandler[index++]= {SASL_CB_GETREALM, (sasl_callback_ft) &getrealm, (void*) asc};
                  break;
               default:
               break;
           }
       }
       p_callbackHandler[index++]= {SASL_CB_LIST_END, NULL, NULL };
       $self->callbackHandler(p_callbackHandler);
    }
}
%extend infinispan::hotrod::RemoteCache<infinispan::hotrod::ByteArray, infinispan::hotrod::ByteArray> {
    DotNetClientListener* addClientListener(ClientListenerCallback *cb, std::vector<char> filterName, std::vector<char> converterName, bool includeCurrentState
                               , const std::vector<std::vector<char> > filterFactoryParam, const std::vector<std::vector<char> > converterFactoryParams, bool useRawData, unsigned char interestFlag)
    {
       DotNetClientListener* cl = new DotNetClientListener();
       cl->includeCurrentState=includeCurrentState;
       cl->filterFactoryName=filterName;
       cl->converterFactoryName=converterName;
       cl->useRawData=useRawData;
       cl->setCb(cb);
       cl->interestFlag=interestFlag;
       $self->addClientListener(*cl, filterFactoryParam, converterFactoryParams, cl->getFailoverFunction());
       return cl;
    }

    void removeClientListener(std::vector<char> listenerId)
    {
       DotNetClientListener cl;
       cl.setListenerId(listenerId);
       $self->removeClientListener(cl);
    }
    
    void deleteListener(DotNetClientListener *l) 
    {
      delete l;
    }
    // Swig doesn-t support std::set. Adding a wrapper to solve the problem
    std::map<std::shared_ptr<infinispan::hotrod::ByteArray>,std::shared_ptr<infinispan::hotrod::ByteArray> > getAll(const std::vector<std::shared_ptr<infinispan::hotrod::ByteArray> >& keyVec)
    {
       std::set<infinispan::hotrod::ByteArray> keySet;
       for (auto i : keyVec)
       {
          keySet.insert(*i);
       }
       return $self->getAll(keySet);
    }
}

