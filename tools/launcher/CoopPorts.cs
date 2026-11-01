using System;
using System.Threading;
using System.Threading.Tasks;
using Mono.Nat;

namespace HordesOfAzeroth.Launcher
{
    sealed class CoopPorts
    {
        static readonly TimeSpan DiscoveryTime = TimeSpan.FromSeconds(6);
        const string Description = "Hordes of Azeroth co-op";

        INatDevice m_device;
        Mapping m_mapping;

        public string Router { get; private set; } = "";

        public async Task<bool> OpenAsync(int port)
        {
            TaskCompletionSource<INatDevice> found = new TaskCompletionSource<INatDevice>(TaskCreationOptions.RunContinuationsAsynchronously);
            void OnFound(object sender, DeviceEventArgs e) => found.TrySetResult(e.Device);
            NatUtility.DeviceFound += OnFound;
            try
            {
                NatUtility.StartDiscovery();
                Task winner = await Task.WhenAny(found.Task, Task.Delay(DiscoveryTime));
                if (winner != found.Task)
                    return false;
                m_device = found.Task.Result;
                m_mapping = new Mapping(Protocol.Tcp, port, port, 0, Description);
                await m_device.CreatePortMapAsync(m_mapping);
                Router = m_device.NatProtocol.ToString();
                return true;
            }
            catch (Exception exception)
            {
                Router = exception.Message;
                return false;
            }
            finally
            {
                NatUtility.DeviceFound -= OnFound;
                NatUtility.StopDiscovery();
            }
        }

        public async Task CloseAsync()
        {
            if (m_device == null || m_mapping == null)
                return;
            try
            {
                using CancellationTokenSource timeout = new CancellationTokenSource(TimeSpan.FromSeconds(3));
                await m_device.DeletePortMapAsync(m_mapping).WaitAsync(timeout.Token);
            }
            catch (Exception)
            {
            }
            m_device = null;
            m_mapping = null;
        }
    }
}
