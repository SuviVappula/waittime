FROM mcr.microsoft.com/powershell

# Copy cron scripts
RUN mkdir /crons
COPY crons/ /crons
RUN chmod +x /crons/*

CMD ./crons/wait-time.ps1
