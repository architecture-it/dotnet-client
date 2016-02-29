%module hotrodcs

%{
#include <infinispan/hotrod/BasicMarshaller.h>
#include <infinispan/hotrod/Builder.h>
#include <infinispan/hotrod/ServerNameId.h>
#include <infinispan/hotrod/FailOverRequestBalancingStrategy.h>
#include <infinispan/hotrod/Configuration.h>
#include <infinispan/hotrod/ConfigurationBuilder.h>
#include <infinispan/hotrod/ConfigurationChildBuilder.h>
#include <infinispan/hotrod/ConnectionPoolConfiguration.h>
#include <infinispan/hotrod/ConnectionPoolConfigurationBuilder.h>
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
#include <infinispan/hotrod/SslConfigurationBuilder.h>
#include <infinispan/hotrod/TimeUnit.h>
#include <infinispan/hotrod/Version.h>
#include <infinispan/hotrod/VersionedValue.h>
#include <infinispan/hotrod/defs.h>
#include <infinispan/hotrod/exceptions.h>
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

%template (VectorChar) std::vector<char>;
%template (ServerNameIdVector) std::vector<infinispan::hotrod::ServerNameId>;

%include "std_shared_ptr.i"
%shared_ptr(infinispan::hotrod::ByteArray)

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

%include "infinispan/hotrod/Builder.h"


%include "infinispan/hotrod/ConnectionPoolConfiguration.h"
%include "infinispan/hotrod/ServerConfiguration.h"
%include "infinispan/hotrod/SslConfiguration.h"
%include "infinispan/hotrod/ServerNameId.h"
%include "infinispan/hotrod/FailOverRequestBalancingStrategy.h"
%include "infinispan/hotrod/Configuration.h"

%template(BuilderConf) infinispan::hotrod::Builder<infinispan::hotrod::Configuration>;
%template(BuilderServerConf) infinispan::hotrod::Builder<infinispan::hotrod::ServerConfiguration>;
%template(BuilderPoolConf) infinispan::hotrod::Builder<infinispan::hotrod::ConnectionPoolConfiguration>;
%template(BuilderSSLConf) infinispan::hotrod::Builder<infinispan::hotrod::SslConfiguration>;

%include "infinispan/hotrod/ConfigurationChildBuilder.h"
%include "infinispan/hotrod/ConnectionPoolConfigurationBuilder.h"
%include "infinispan/hotrod/ServerConfigurationBuilder.h"
%include "infinispan/hotrod/SslConfigurationBuilder.h"
%include "infinispan/hotrod/ConfigurationBuilder.h"

%include "infinispan/hotrod/RemoteCacheBase.h"
%include "infinispan/hotrod/RemoteCache.h"
%include "infinispan/hotrod/RemoteCacheManager.h"
%include "arrays_csharp.i"
%apply unsigned char INPUT[] {unsigned char* _bytes}
%apply unsigned char OUTPUT[] {unsigned char* dest_bytes}
%newobject infinispan::hotrod::BasicMarchaller<ByteArray>::unmarshall;

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
%template(ByteArrayVector) std::vector<std::shared_ptr<infinispan::hotrod::ByteArray> >;
%template(ServerConfigurationVector) std::vector<infinispan::hotrod::ServerConfiguration>;
%extend infinispan::hotrod::RemoteCacheManager {
    %template(getByteArrayCache) getCache<infinispan::hotrod::ByteArray, infinispan::hotrod::ByteArray>;
};

