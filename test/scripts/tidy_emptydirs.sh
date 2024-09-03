tidy_emptydirs() {
    echo "Starting tidy_emptydirs at $(date)" >> /var/log/tidy_emptydirs.log
    echo "Checking directory: $pkgdir" >> /var/log/tidy_emptydirs.log
    find "$pkgdir" -type d -empty -print >> /var/log/tidy_emptydirs.log
    echo "Finished tidy_emptydirs at $(date)" >> /var/log/tidy_emptydirs.log
}
