﻿using Infinispan.HotRod;
using Infinispan.HotRod.Config;
using Infinispan.HotRod.Tests.Util;
using Infinispan.HotRod.Transport;
using NUnit.Framework;
using System;
using System.Collections.Generic;
using Infinispan.HotRod.Tests.ClusteredXml2;

namespace Infinispan.HotRod.Tests.ClusteredXml2
{
    class StickyBalancingStragegy : Infinispan.HotRod.Transport.FailOverRequestBalancingStrategy
    {
        IList<InetSocketAddress> servers;
        public InetSocketAddress nextServer(IList<InetSocketAddress> failedServers)
        {
            if (servers.Count == 1)
                return servers[0];
            // Always choose the 11322 server, the choose 11222 on failure
            if (failedServers.Count == 0)
            {
                return (servers[0].Port == 11322) ? servers[0] : servers[1];
            }
            else
            {
                return (servers[0].Port == 11322) ? servers[1] : servers[0];
            }

            throw new System.Exception("No transport");
        }
        public void setServers(IList<InetSocketAddress> servers)
        {
            this.servers = servers;
        }
    }

    [TestFixture]
    [Category("clustered_xml_2")]
    [Category("ClusterTestSuite")]
    public class NearCacheFailoverTest
    {

        [SetUp]
        public void BeforeAnyTest()
        {
            ClusterTestSuite.EnsureServersUp();
            remoteManager = getRemoteCacheManager();
        }

        [TearDown]
        public void AfterAnyTest()
        {
            remoteManager.Stop();
        }

        public static RemoteCacheManager getRemoteCacheManager()
        {
            ConfigurationBuilder conf = new ConfigurationBuilder();
            conf.AddServer().Host("127.0.0.1").Port(11222);
            conf.AddServer().Host("127.0.0.1").Port(11322)
                .ConnectionTimeout(90000).SocketTimeout(6000)
                .NearCache().Mode(NearCacheMode.INVALIDATED).MaxEntries(10);
            conf.BalancingStrategyProducer(d);
            marshaller = new JBasicMarshaller();
            conf.Marshaller(marshaller);
            return ClusterTestSuite.getRemoteCacheManager(conf.Build());
        }

        RemoteCacheManager remoteManager;
        static IMarshaller marshaller;
        static StickyBalancingStragegy b;

        static FailOverRequestBalancingStrategyProducerDelegate d = delegate ()
        {
            b = new StickyBalancingStragegy();
            return b;
        };

        [Test]
        public void NearCacheWithFailoverTest()
        {
            var cache = remoteManager.GetCache<string, string>();
            cache.Clear();
            ServerStatistics stats0 = cache.Stats();
            cache.Put("key1", "value1");
            cache.Get("key1");
            var stats1 = cache.Stats();
            Assert.AreEqual(int.Parse(stats0.GetStatsMap()["nearHits"]), int.Parse(stats1.GetStatsMap()["nearHits"]));
            string retVal = cache.Get("key1");         // near hit
            Assert.AreEqual("value1", retVal);
            var stats2 = cache.Stats();
            Assert.AreEqual(int.Parse(stats1.GetStatsMap()["nearHits"]) + 1, int.Parse(stats2.GetStatsMap()["nearHits"]));
            ClusterTestSuite.server2.ShutDownHotrodServer();
            // After the shutdown the client failover on the 11222 server and reset the near cache
            // let's verify that the get operation goes remotes
            ServerStatistics stats3 =null;
            // .Stat operation could fail for a while because the cluster suspects a split brain
            // do some retries
            for (var i = 0; i < 10; ++i)
            {
                try
                {
                    stats3 = cache.Stats();
                    break;
                }
                catch (Exception)
                {
                    System.Threading.Thread.Sleep(1000);
                }
            }
            // Assert that .Stats eventually succeeded
            Assert.IsNotNull(stats3);

            // The failover event needs some time to be detected, retries are needed
            ServerStatistics stats4=null;
            for (var i = 0; i < 10; ++i)
            {
                stats3 = cache.Stats();
                retVal = cache.Get("key1");         // remote hit
                Assert.AreEqual("value1", retVal);
                stats4 = cache.Stats();
                if (int.Parse(stats3.GetStatsMap()["nearHits"]) == int.Parse(stats4.GetStatsMap()["nearHits"]))
                    break;
                System.Threading.Thread.Sleep(1000);
            }
            Assert.AreEqual(int.Parse(stats3.GetStatsMap()["nearHits"]), int.Parse(stats4.GetStatsMap()["nearHits"]));
            // Now try that near cache is working again
            retVal = cache.Get("key1");         // near hit
            Assert.AreEqual("value1", retVal);
            ServerStatistics stats5 = cache.Stats();
            Assert.AreEqual(int.Parse(stats4.GetStatsMap()["nearHits"])+1, int.Parse(stats5.GetStatsMap()["nearHits"]));
        }
    }
}
